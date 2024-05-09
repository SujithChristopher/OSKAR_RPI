import numpy as np
import cv2
from cv2 import aruco
import msgpack as mp
import msgpack_numpy as mpn
import threading
import socket
from ultralytics import YOLO

model = YOLO(r"D:\CMC\ArmBo_games\OSKAR_GAME_v2\pyfiles\model.pt")


ARUCO_PARAMETERS = aruco.DetectorParameters()
ARUCO_DICT = aruco.getPredefinedDictionary(aruco.DICT_ARUCO_MIP_36H12)
detector = aruco.ArucoDetector(ARUCO_DICT, ARUCO_PARAMETERS)
markerLength = 0.05
markerSeperation = 0.01

board = aruco.GridBoard(
        size= [1,1],
        markerLength=markerLength,
        markerSeparation=markerSeperation,
        dictionary=ARUCO_DICT)
            
def estimate_pose_single_markers(corners, marker_size, camera_matrix, distortion_coefficients):
    marker_points = np.array([[-marker_size / 2, marker_size / 2, 0],
                              [marker_size / 2, marker_size / 2, 0],
                              [marker_size / 2, -marker_size / 2, 0],
                              [-marker_size / 2, -marker_size / 2, 0]], dtype=np.float32)
    rvecs = []
    tvecs = []
    for corner in corners:
        _, r, t = cv2.solvePnP(marker_points, corner, camera_matrix, distortion_coefficients, True, flags=cv2.SOLVEPNP_IPPE_SQUARE)
        if r is not None and t is not None:
            r = np.array(r).reshape(1, 3).tolist()
            t = np.array(t).reshape(1, 3).tolist()
            rvecs.append(r)
            tvecs.append(t)
    return np.array(rvecs, dtype=np.float32), np.array(tvecs, dtype=np.float32)



class MainClass:
    def __init__(self, cam_calib_path, udp_stream=False):
        self.ar_pos = None
        self.UDP_STREAM = udp_stream
        
        self.rvec = None
        self.tvec = None
        self.first_rvec = None
        self.first_tvec = None
        
        self.FIRST_FRAME = True
        cam_calib_path = cam_calib_path
        
        self.default_ids = [12, 88, 89]
        self.received_message = ""
        self.stop_signal = False
        # print("hello world")
        
        with open(cam_calib_path, "rb") as f:
            ar_cam = mp.Unpacker(f, object_hook=mpn.decode)
            self.camera_matrix, self.distortion_coeff = next(ar_cam)
            # print(self.camera_matrix, self.distortion_coeff)
        
        if self.UDP_STREAM:
            udp_ip = "localhost"
            udp_port = 8000
            self.udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.udp_socket.bind((udp_ip, udp_port))
            self.udp_socket.settimeout(1)
            print(self.udp_socket.getsockname())
    
    def camera_thread(self):
        self.cap = cv2.VideoCapture(1, cv2.CAP_DSHOW)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        self.cap.set(cv2.CAP_PROP_FPS, 30)
        while True:    
            if self.UDP_STREAM:
                self.received_message, self.addr = self.udp_socket.recvfrom(1024)
                
                if self.received_message.decode("utf-8") == "stop":
                    self.udp_socket.sendto('stop'.encode('utf-8'), self.addr)
                    self.udp_socket.close()
                    break
            if self.received_message.decode("utf-8") == "stop":
                self.udp_socket.sendto('stop'.encode('utf-8'), self.addr)
                self.udp_socket.close()
                break
            ret, self.video_frame = self.cap.read()
            if ret:
                self.colorImage = self.video_frame
                if self.FIRST_FRAME:
                    yolo_results = model.predict(self.colorImage, verbose=False, imgsz=640)[0]
                    self.colorImage = yolo_results.plot()
                    modelcorners = []
                    for _keys in yolo_results.keypoints.data:
                        modelcorners.append(_keys[0:4].cpu().numpy())
                    modelcorners = np.array(modelcorners)
                    corners = modelcorners                            
                    if len(yolo_results.boxes.cls.cpu().numpy()) != 0: # if there are any detections else None
                        _idx = yolo_results.boxes.cls.cpu().numpy()
                        ids = []
                        for i in _idx:
                            match i:
                                case 0:
                                    ids.append([12])
                                case 1:
                                    ids.append([88])
                                case 2:
                                    ids.append([89])
                        ids = np.array(ids, dtype=np.int32)
                    else:
                        ids = None
                        
                    if ids is not None:
                        self.first_rvec, self.first_tvec = estimate_pose_single_markers(corners, markerLength, self.camera_matrix, self.distortion_coeff)
                        self.FIRST_FRAME = False
                        
                else:
                    yolo_results = model.predict(self.colorImage, verbose=False, imgsz=640)[0]
                    self.colorImage = yolo_results.plot()
                    modelcorners = []
                    for _keys in yolo_results.keypoints.data:
                        modelcorners.append(_keys[0:4].cpu().numpy())
                    modelcorners = np.array(modelcorners)
                    corners = modelcorners
                    if len(yolo_results.boxes.cls.cpu().numpy()) != 0: # if there are any detections else None
                        _idx = yolo_results.boxes.cls.cpu().numpy()
                        ids = []
                        for i in _idx:
                            match i:
                                case 0:
                                    ids.append([12])
                                case 1:
                                    ids.append([88])
                                case 2:
                                    ids.append([89])
                        ids = np.array(ids, dtype=np.int32)

                        if (ids is not None and len(ids) > 0) and all(item in self.default_ids for item in np.array(ids)):
                            self.rvec, self.tvec = estimate_pose_single_markers(corners, markerLength, self.camera_matrix, self.distortion_coeff)
                            
                            for _r, _t in zip(self.rvec, self.tvec):
                                cv2.drawFrameAxes(self.video_frame, self.camera_matrix, self.distortion_coeff, _r, _t, 0.05)
                            self.rvec = self.rvec - self.first_rvec
                            self.tvec = self.tvec - self.first_tvec                 
                        
                            self.tvec_cm = self.tvec *70
                            self.tvec_x = str(self.tvec_cm[0][0][0]) + "," + str(self.tvec_cm[0][0][2])
                            if self.UDP_STREAM:
                                self.udp_socket.sendto(str(self.tvec_x).encode('utf-8'), self.addr)
                        else:
                            if self.UDP_STREAM:
                                self.udp_socket.sendto('none'.encode('utf-8'), self.addr)
                cv2.imshow("frame", self.video_frame)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
    
    def run(self):
        # t1 = threading.Thread(target=self.camera_thread)
        # t1.start()
        # t1.join()
        self.camera_thread()
        # self.camera_thread()    

if __name__ == "__main__":
    import os
    _cur_dir = os.getcwd()
    _file_path = os.path.join(_cur_dir, "pyfiles", "camera_calibration.msgpack")
    # _file_path = os.path.join(_cur_dir, "camera_calibration.msgpack")
    print(os.path.exists(_file_path))
    print(_file_path)
    
    """
    Check these parameters
    """
    UDP_STREAM = True
    CAMERA_CALIBRATION_FILE = _file_path
    
    """
    Then run the main program
    """
    
    main = MainClass(cam_calib_path=CAMERA_CALIBRATION_FILE,udp_stream=UDP_STREAM)
    main.run()
import numpy as np
import cv2
from cv2 import aruco
import msgpack as mp
import msgpack_numpy as mpn
import threading
import socket
from ultralytics import YOLO
from scipy.spatial.transform import Rotation as R

model = YOLO(r"D:\CMC\ArmBo_games\OSKAR_GAME_v3\pyfiles\model.pt")


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
        self.close_file = False
        
        self.FIRST_FRAME = True
        cam_calib_path = cam_calib_path
        
        self.default_ids = [12, 88, 89]
        self.received_message = ""
        self.stop_signal = False
        
        self.RMAT_INIT = False
        self.initial_rmat = np.eye(3)

        self.tvec_12 = np.nan
        self.tvec_88 = np.nan
        self.tvec_89 = np.nan
        
        self.rvec_12 = np.nan
        self.rvec_88 = np.nan
        self.rvec_89 = np.nan
        
        self.tv_origin = np.zeros((3, 1))
        
        self.default_ids = np.array([12, 88, 89])
        self.does_not_exist = []
        
        self.p_90 = (R.from_euler('zyx', [0, 90, 0], degrees=True)).as_matrix()
        self.n_90 = (R.from_euler('zyx', [0, -90, 0], degrees=True)).as_matrix()
        self.zero_vec = np.zeros(3)
        self.tvec_dist = np.zeros(3)
        self.temp_tvec = np.zeros((3,1))
        self.rmat = np.eye(3)
        self.save_first_frame = False
        
        # self.save_data_path = os.path.join(os.getcwd(), "pyfiles", "data", "data.msgpack")
        self.save_data_path = r"D:\CMC\export_games\rom_data.msgpack"
        self.raw_data = r"D:\CMC\export_games\data.msgpack"
        self.first_frame_file = r"D:\CMC\export_games\first_frame.msgpack"

        self.data_file = open(self.save_data_path, 'wb')
        self.raw_data_file = open(self.raw_data, 'wb')
        self.raw_data_trigger = False
                        
        with open(cam_calib_path, "rb") as f:
            ar_cam = mp.Unpacker(f, object_hook=mpn.decode)
            self.camera_matrix, self.distortion_coeff = next(ar_cam)
        
        if self.UDP_STREAM:
            udp_ip = "localhost"
            udp_port = 8000
            self.udp_socket = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
            self.udp_socket.bind((udp_ip, udp_port))
            self.udp_socket.settimeout(5)
            print(self.udp_socket.getsockname())
    
    def preprocess_ids(self, ids, rotation_vectors, translation_vectors):
        self.does_not_exist = []
        for idx, id in enumerate(ids):
            match np.array(id):
                case 12:
                    self.tvec_12 = translation_vectors[idx][0]
                    self.rvec_12 = rotation_vectors[idx][0]
                case 88:
                    self.tvec_88 = translation_vectors[idx][0]
                    self.rvec_88 = rotation_vectors[idx][0]
                case 89:
                    self.tvec_89 = translation_vectors[idx][0]
                    self.rvec_89 = rotation_vectors[idx][0]
        _ids = np.array(ids)
        if self.default_ids[0] not in _ids:
            self.does_not_exist.append(self.default_ids[0])
        if self.default_ids[1] not in _ids:
            self.does_not_exist.append(self.default_ids[1])
        if self.default_ids[2] not in _ids:
            self.does_not_exist.append(self.default_ids[2])
            
        for _d in self.does_not_exist:
            match np.array(_d):
                case 12:
                    self.tvec_12 = np.nan
                    self.rvec_12 = np.nan
                case 88:
                    self.tvec_88 = np.nan
                    self.rvec_88 = np.nan
                case 89:
                    self.tvec_89 = np.nan
                    self.rvec_89 = np.nan
                    
    def coordinate_transform(self):
        tv_12 = np.nan
        tv_88 = np.nan
        tv_89 = np.nan
        
        rm_12 = np.eye(3)
        rm_88 = np.eye(3)
        rm_89 = np.eye(3)
        
        id_12_offset = np.array([-0.05, 0.03, -0.055]).reshape(3, 1)
        id_88_offset = np.array([0.00, 0.03, -0.11]).reshape(3, 1)
        id_89_offset = np.array([0.05, 0.03, -0.055]).reshape(3, 1)
                
        if self.tvec_12 is not np.nan:
            tv_12 = np.array(self.tvec_12).reshape(3, 1)
            rm_12 = cv2.Rodrigues(self.rvec_12)[0]
        if self.tvec_88 is not np.nan:
            tv_88 = np.array(self.tvec_88).reshape(3, 1)
            rm_88 = cv2.Rodrigues(self.rvec_88)[0]
        if self.tvec_89 is not np.nan:
            tv_89 = np.array(self.tvec_89).reshape(3, 1)
            rm_89 = cv2.Rodrigues(self.rvec_89)[0]
        
        pa_c_12 = rm_12 @ id_12_offset + tv_12
        pa_b_c_12 = self.initial_rmat.T @ (pa_c_12 - self.tv_origin)
        
        pa_c_88 = rm_88 @ id_88_offset + tv_88
        pa_b_c_88 = self.initial_rmat.T @ (pa_c_88 - self.tv_origin)

        pa_c_89 = rm_89 @ id_89_offset + tv_89
        pa_b_c_89 = self.initial_rmat.T @ (pa_c_89 - self.tv_origin)
        
        self.tvec_dist = np.nanmedian(np.array([pa_b_c_12, pa_b_c_88, pa_b_c_89]), axis=0)
        self.tvec_dist = self.tvec_dist.T[0]
    
    def camera_thread(self):
        self.cap = cv2.VideoCapture(0, cv2.CAP_DSHOW)
        self.cap.set(cv2.CAP_PROP_FRAME_WIDTH, 1280)
        self.cap.set(cv2.CAP_PROP_FRAME_HEIGHT, 720)
        self.cap.set(cv2.CAP_PROP_FPS, 30)
        while True:    
            if self.UDP_STREAM:
                self.received_message, self.addr = self.udp_socket.recvfrom(30)
                
                if self.received_message.decode("utf-8") == "stop":
                    self.udp_socket.sendto('stop'.encode('utf-8'), self.addr)
                    self.udp_socket.close()
                    break
                
                if self.received_message.decode("utf-8") == "close":
                    self.udp_socket.sendto('close'.encode('utf-8'), self.addr)
                    self.data_file.close()
                    self.close_file = True
                    self.raw_data_trigger = True
                
                if self.received_message.decode("utf-8") == "set_orgin":
                    self.save_first_frame = True
                    self.udp_socket.sendto('saved'.encode('utf-8'), self.addr)
                
            ret, self.video_frame = self.cap.read()
            if ret:
                self.colorImage = self.video_frame
                if self.FIRST_FRAME:
                    yolo_results = model.predict(self.colorImage, verbose=False, imgsz=640, conf=0.8)[0]
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
                        self.preprocess_ids(ids, self.first_rvec, self.first_tvec)
                        self.coordinate_transform()
                        self.first_tvec = self.tvec_dist
                        
                        self.FIRST_FRAME = False
                        
                else:
                    yolo_results = model.predict(self.colorImage, verbose=False, imgsz=640, conf=0.8)[0]
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
                            self.preprocess_ids(ids, self.rvec, self.tvec)
                            
                            for _r, _t in zip(self.rvec, self.tvec):
                                cv2.drawFrameAxes(self.colorImage, self.camera_matrix, self.distortion_coeff, _r, _t, 0.05)
                                
                            self.coordinate_transform()        
                            self.tv = self.tvec_dist - self.first_tvec    
                            self.tvec_cm = self.tv *70 * 25
                            self.tvec_x = str(-1*self.tvec_cm[0]) + "," + str(self.tvec_cm[2])
                            if not self.close_file:
                                decoded = mp.packb([self.tv[0], self.tv[2]], default=mpn.encode)
                                self.data_file.write(decoded)
                                
                            if self.raw_data_trigger:
                                self.decoded = mp.packb([self.tv[0], self.tv[2]], default=mpn.encode)
                                self.raw_data_file.write(self.decoded)
                                
                            if self.save_first_frame:
                                self.decoded = mp.packb([self.first_tvec[0], self.first_tvec[2]], default=mpn.encode)
                                with open(self.first_frame_file, 'wb') as f:
                                    f.write(self.decoded)
                                self.save_first_frame = False
                                                                
                            if self.UDP_STREAM:
                                self.udp_socket.sendto(str(self.tvec_x).encode('utf-8'), self.addr)
                        else:
                            if self.UDP_STREAM:
                                self.udp_socket.sendto('none'.encode('utf-8'), self.addr)
                cv2.imshow("frame", self.colorImage)
            if cv2.waitKey(1) & 0xFF == ord('q'):
                break
        cv2.destroyAllWindows()
        self.data_file.close()
        self.raw_data_file.close()

    def run(self):
        self.camera_thread()

if __name__ == "__main__":
    import os
    _cur_dir = os.getcwd()
    _file_path = os.path.join(_cur_dir, "pyfiles", "camera_calibration.msgpack")
    _file_path = r"D:\CMC\ArmBo_games\OSKAR_GAME_v2\pyfiles\camera_calibration.msgpack"
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
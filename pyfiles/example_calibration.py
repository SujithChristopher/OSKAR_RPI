import cv2
from cv2 import aruco
import numpy as np
import msgpack as mp
import msgpack_numpy as mpn

ARUCO_PARAMETERS = aruco.DetectorParameters()
ARUCO_DICT = aruco.getPredefinedDictionary(aruco.DICT_ARUCO_ORIGINAL)
detector = aruco.ArucoDetector(ARUCO_DICT, ARUCO_PARAMETERS)
markerLength = 0.05
markerSeperation = 0.01

board = aruco.GridBoard(
        size= [1,1],
        markerLength=markerLength,  
        markerSeparation=markerSeperation,
        dictionary=ARUCO_DICT)

_video_pth = 'video path'
_video_file = open(_video_pth, "rb")
_video_data = mp.Unpacker(_video_file, object_hook=mpn.decode)
_video_length = 0

for _frame in _video_data:
    _video_length += 1

_video_file.close()


# Selecting random 150 frames
marker_corners = []
marker_ids = []
counter = 0
rnd = np.random.choice(_video_length, 150, replace=False)
for idx, _frame in enumerate(_video_data):
    
    if idx in rnd:
        corners, ids, rejected_image_points = detector.detectMarkers(_frame)

        corners, ids, _, _ = detector.refineDetectedMarkers(_frame, board, corners, ids, rejected_image_points) 

        if ids is not None:
            marker_corners.append(corners)
            marker_ids.append(ids)
            counter+=1

_video_file.close()


# processing the corners
processed_image_points = []
processed_object_points = []
for _f in range(len(marker_corners)):
    current_object_points, current_image_points = board.matchImagePoints(marker_corners[_f], marker_ids[_f])
    try:
        if current_object_points.any() and current_image_points.any():
            processed_image_points.append(current_image_points)
            processed_object_points.append(current_object_points)
    except:
        pass
    
    
mtx2 = np.zeros((3, 3))
dist2 = np.zeros((1, 8))
# camera calibration 
_, mtx1, dist1, _, _=cv2.calibrateCamera(processed_object_points, processed_image_points, _frame.shape[:2], mtx2, dist2)

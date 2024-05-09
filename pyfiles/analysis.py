import numpy as np
import msgpack as mp
import msgpack_numpy as mpn
import math
import matplotlib.pyplot as plt
from scipy.interpolate import splprep, splev
from scipy.ndimage import gaussian_filter1d
from scipy.signal import savgol_filter
import cv2
from scipy.stats import zscore

def calculate_centroid(coords):
    """Calculate the centroid of a polygon."""
    x_sum = sum(x for x, y in coords)
    y_sum = sum(y for x, y in coords)
    return x_sum / len(coords), y_sum / len(coords)

def angle_with_centroid(centroid, point):
    """Calculate the angle of a point with respect to a centroid."""
    return math.atan2(point[1] - centroid[1], point[0] - centroid[0])

def sort_vertices(coords):
    """Sort vertices based on their angle with the centroid."""
    centroid = calculate_centroid(coords)
    return sorted(coords, key=lambda point: angle_with_centroid(centroid, point))

def polygon_area(coords):
    """Calculate the area of a polygon given its vertices."""
    n = len(coords)
    area = 0.0
    
    for i in range(n):
        j = (i + 1) % n
        area += coords[i][0] * coords[j][1]
        area -= coords[j][0] * coords[i][1]
    
    area = abs(area) / 2.0
    return area

class Analysis:
    def poly_area(self, x, y):
        return 0.5*np.abs(np.dot(x,np.roll(y,1))-np.dot(y,np.roll(x,1)))
    
    def polygon_area(self, coords):
        n = len(coords)
        area = 0
        
        for i in range(n):
            j = (i + 1) % n  # Ensure the list wraps around to the beginning
            area += coords[i][0] * coords[j][1]
            area -= coords[j][0] * coords[i][1]
        
        area = abs(area) / 2.0
        return area*100

    def __init__(self):
        # self.data_path = os.path.join(os.getcwd(), "pyfiles", "data", "data.msgpack")
        self.data_path =r"D:\CMC\export_games\data.msgpack"
        self.data_file = open(self.data_path, 'rb')
        self.data = mp.Unpacker(self.data_file, object_hook=mpn.decode)
                
    def run(self):
        tvecs = []
        for i in self.data:
            tvecs.append(i)
        self.ar = np.array(tvecs, dtype=np.float32)
        self.ar = self.ar*100
        # print(self.ar)
        # self.ar = self.ar[0]
        
        x_range = abs(min(self.ar[:,0])) + abs(max(self.ar[:,0]))
        y_range = abs(min(self.ar[:,1])) + abs(max(self.ar[:,1]))
        print(round(polygon_area(sort_vertices(self.ar)), 2), 'cm^2')
        print(round(polygon_area(self.ar), 2), 'cm^2')
        print(str(round(x_range, 2)) + ' cm')
        print(str(round(y_range, 2)) + ' cm')

        
        self.sort_vert = np.array(sort_vertices(self.ar))
        x_coords = self.sort_vert[:, 0]
        y_coords = self.sort_vert[:, 1]
        tck, u = splprep([x_coords, y_coords], s=0)
        u_new = np.linspace(0, 1, num=100)
        x_spline, y_spline = splev(u_new, tck, der=0.1)

        sigma = 3  # Adjust this value for more or less smoothing
        x_smooth = gaussian_filter1d(x_coords, sigma=sigma)
        y_smooth = gaussian_filter1d(y_coords, sigma=sigma)

        
        hull = cv2.convexHull(self.sort_vert)
        # print(hull)
        hull = np.array(hull).squeeze()
        # print(hull[:,0])
        plt.plot(x_smooth, y_smooth)
        plt.fill(x_smooth, y_smooth, color='orange', alpha=0.3)
        
        plt.scatter(self.ar[:,0], self.ar[:,1], s=1, color='red')
        plt.title('Movement Coordinates')
        plt.xlabel('X (cm)')
        plt.ylabel('Y (cm)')
        plt.xlim(-30, 100)
        plt.ylim(-30, 100)
        plt.tight_layout()
        plt.savefig('analysis.png')   
        plt.plot(hull[:,0], hull[:,1])
        plt.plot(hull[:,0], hull[:,1])
  
        plt.show()   
        
        self.data_file.close()
        

Analysis().run()
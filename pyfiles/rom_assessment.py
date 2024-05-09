import numpy as np
import msgpack as mp
import msgpack_numpy as mpn
import cv2

class Analysis:

    def __init__(self):
        self.data_path =r"D:\CMC\export_games\rom_data.msgpack"
        self.data_file = open(self.data_path, 'rb')
        self.data = mp.Unpacker(self.data_file, object_hook=mpn.decode)
                
    def run(self):
        tvecs = []
        for i in self.data:
            tvecs.append(i)
        self.ar = np.array(tvecs, dtype=np.float32)
        self.ar = self.ar*1,750
        self.ar = self.ar[0] 
        
        x, y, w, h = cv2.boundingRect(np.array(self.ar*1750))
        x = x+600
        y = y+400
        print(str(x) + ',' + str(y) + ',' + str(x+w) + ',' + str(y+h))

        self.data_file.close()
        

Analysis().run()
from dataclasses import dataclass
from tools import *

import numpy as np

class Camera:
    def __init__(self, r1 : np.array, phi : float, theta : float):
        assert r1.shape == (3,)

        self.r1 = r1
        self.r1_temp = 0, 0, 0

        self.camThetaBase = 0
        self.camPhiBase = 0

        self.camTheta = theta
        self.camPhi = phi

        r1_temp = self.rotateCam()
        self.camMat = self.getCam(r1_temp)


    def getCam(self, r1):
        camF = normalize(r1)
        camR = normalize(cross(vec3(0, 1, 0), camF))
        camU = cross(camF, camR)

        mat_ = mat3(camR, camU, camF)
        return mat_

    def rotateCam(self):
        yz = vec2(self.r1[1], self.r1[2])
        new_yz = pR(yz, self.camTheta + self.camThetaBase)
        xz = vec2(self.r1[0], new_yz[1])
        new_xz = pR(xz, self.camPhi + self.camPhiBase)

        vec = vec3(new_xz[0], new_yz[0], new_xz[1])


        return vec

    @staticmethod
    def mouseToAngle(u_mouse, u_resolution):
        m = (u_mouse - u_resolution / 2) / u_resolution
        return m

    def update(self):
        self.r1_temp = self.rotateCam()
        self.camMat = self.getCam(self.r1_temp)












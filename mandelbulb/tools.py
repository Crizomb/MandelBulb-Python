import numpy as np
from numpy import cos, sin, tan, exp

from numpy.linalg import norm, det
from numpy import cross
import numba
from dataclasses import dataclass

PI = np.pi
TAU = 2*np.pi



def vec2(x, y, dtype=float):
    return np.array((x, y), dtype=dtype)

def vec3(x, y, z, dtype=float):
    return np.array((x, y, z), dtype=dtype)

def mat3(a : np.array, b : np.array, c : np.array):
    return np.array((a, b, c)).T

def mat3ToTuple(m):
    return m[0, 0], m[0, 1], m[0, 2], m[1, 0], m[1, 1], m[1, 2], m[2, 0], m[2, 1], m[2, 2]
    #return m[0, 0], m[1, 0], m[2, 0], m[0, 1], m[1, 1], m[2, 1], m[0, 2], m[1, 2], m[2, 2]

def getRot2D(theta):
    return np.array( [( cos(theta), -sin(theta) ), (sin(theta), cos(theta))] )

def pR(p, a):
    return cos(a)*p + sin(a)*vec2(p[1], -p[0])


def add_tuples(t1, t2):
    assert len(t1) == len(t2)
    temp = [0]*len(t1)
    for i in range(len(t1)):
        temp[i] += t1[i] + t2[i]
    return tuple(temp)

def mult_ext_tuples(a, t1):
    return tuple([a*t for t in t1])

def normalize(vec):
    return vec/norm(vec)




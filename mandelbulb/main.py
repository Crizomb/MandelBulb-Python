import moderngl_window as mglw
from tools import *
from camera import Camera
from time import sleep

print(__name__)

class App(mglw.WindowConfig):
    window_size = 1600, 900
    ro = 0, -0.5, -1.5
    ro = mult_ext_tuples(1, ro)
    rc = 0, -1, 2
    u_mouse = 0, 0
    forward = False
    backward = False
    resource_dir = 'resources/programs'
    cam = Camera(vec3(*rc), 0, 0)

    mouse_pressed = False


    def __init__(self, **kwargs):
        super().__init__(**kwargs)
        self.quad = mglw.geometry.quad_fs()
        self.program = self.load_program(vertex_shader='vertex.glsl', fragment_shader='fragment.glsl')
        # uniforms
        self.set_uniform('u_resolution', self.window_size)
        self.set_uniform('ro', self.ro)
        self.set_uniform('rc', self.rc)
        #self.set_uniform('u_mouse', self.u_mouse)
        self.set_uniform('cam', mat3ToTuple(np.eye(3)))

    def set_uniform(self, u_name, u_value):
        try:
            self.program[u_name] = u_value
        except KeyError:
            None
            print(f'{u_name} not used in shader')



    def moove(self):
        x, y, z = tuple(self.cam.r1_temp)
        x = -x
        y = -y
        if self.forward:
            self.ro = add_tuples(self.ro, mult_ext_tuples(0.1, (x, y, z)))

        if self.backward:
            self.ro = add_tuples(self.ro, mult_ext_tuples(-0.1, (x, y, z)))


    def cam_render(self):
        angles = self.cam.mouseToAngle(vec2(*self.u_mouse), vec2(*self.window_size))
        self.cam.camPhi, self.cam.camTheta = -angles[0]*4, angles[1]*2
        self.cam.update()

    def render(self, time, frame_time):
        self.ctx.clear()
        #self.program['u_time'] = time
        self.quad.render(self.program)
        self.set_uniform('cam', mat3ToTuple(self.cam.camMat))

        if self.mouse_pressed:
            self.cam_render()

        if self.forward or self.backward:
            self.moove()

        self.set_uniform('ro', self.ro)


        sleep(0)



    def mouse_drag_event(self, x: int, y: int, dx: int, dy: int):
        self.u_mouse = x, y
        self.mouse_pressed = True

    def mouse_release_event(self, x: int, y: int, button: int):
        self.mouse_pressed = False
        self.cam.camThetaBase += self.cam.camTheta
        self.cam.camPhiBase += self.cam.camPhi



    def key_event(self, key, action, modifiers):

        match key:
            case self.wnd.keys.UP:
                if action == self.wnd.keys.ACTION_PRESS:
                    self.forward = True
                elif action == self.wnd.keys.ACTION_RELEASE:
                    self.forward = False

            case self.wnd.keys.DOWN:
                if action == self.wnd.keys.ACTION_PRESS:
                    self.backward = True
                elif action == self.wnd.keys.ACTION_RELEASE:
                    self.backward = False






if __name__ == '__main__':
    mglw.run_window_config(App)
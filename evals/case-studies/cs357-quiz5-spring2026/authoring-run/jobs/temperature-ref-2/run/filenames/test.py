from pl_helpers import name, points
from pl_unit_test import PLTestCase
from code_feedback import Feedback as feedback

import numpy as np

class Test(PLTestCase):

    def _test_inner(self, coeffs):
        score = 0
        temp_func, temp_grad, temp_hess, start_coords = self.ref.generate_temperature_func(coeffs)
        ref_coords, ref_elevation, ref_temp_type = self.ref.find_temperature_extreme(temp_func, temp_grad, temp_hess, start_coords.copy())
        st_tup = feedback.call_user(self.st.find_temperature_extreme, temp_func, temp_grad, temp_hess, start_coords.copy())
        if type(st_tup) != tuple or len(st_tup) != 3:
            feedback.add_feedback("find_temperature_extreme did not return a tuple of size 3")
        else:
            st_coords, st_elevation, st_temp_type = st_tup
            if feedback.check_numpy_array_allclose("coords", ref_coords, st_coords):
                score += 1
            if feedback.check_scalar("temperature", ref_elevation, st_elevation):
                score += 1
            if type(st_temp_type) != str:
                feedback.add_feedback("temp_type (3rd value in tuple) is not a string")
            elif ref_temp_type != st_temp_type:
                feedback.add_feedback("temp_type (3rd value in tuple) is not correct")
            else:
                score += 1
                feedback.add_feedback("temp_type (3rd value in tuple) is correct")

        feedback.set_score(score / 3)

    @points(5)
    @name("max_test")
    def test_0(self):
        # All negative leads to a maximum
        self._test_inner((-1, -1, -1))

    @points(5)
    @name("min_test")
    def test_1(self):
        # All positive leads to a minimum
        self._test_inner((1, 1, 1))

    @points(5)
    @name("saddle_test")
    def test_2(self):
        rng = np.random.default_rng()
        coeffs = [1, 1, 1]
        # Choose between 1 and 2 random indices to flip
        idx1, idx2 = rng.choice(3, size=2, replace=False)
        coeffs[idx1] = -1
        if rng.random() > 0.5:
            coeffs[idx2] = -1
        self._test_inner(coeffs)

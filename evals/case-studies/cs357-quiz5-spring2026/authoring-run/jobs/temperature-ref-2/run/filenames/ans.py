import numpy as np
import numpy.linalg as la

def find_temperature_extreme(temperature_func, temperature_grad, temperature_hess, start_coords):
    # Newton's Method
    temp_coords = start_coords
    prev_guess = temp_coords - 1
    while la.norm(temp_coords - prev_guess, 2) > 1e-3:
        prev_guess = temp_coords.copy()
        s = la.solve(temperature_hess(temp_coords), temperature_grad(temp_coords))
        temp_coords -= s
    # Hessian gives us whether we're at a min or a max
    vals, _ = la.eig(temperature_hess(temp_coords))
    temp_type = "saddle"
    if np.all(vals > 0):
        temp_type = "min"
    elif np.all(vals < 0):
        temp_type = "max"
    temp_value = temperature_func(temp_coords)
    return (temp_coords, temp_value, temp_type)

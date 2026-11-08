import numpy as np
import numpy.linalg as la

def find_terrain_extreme(terrain_func, terrain_grad, terrain_hess, start_coords):
    # Newton's Method
    temp_coords = start_coords
    prev_guess = temp_coords - 1
    while la.norm(temp_coords - prev_guess, 2) > 1e-3:
        prev_guess = temp_coords.copy()
        s = la.solve(terrain_hess(temp_coords), terrain_grad(temp_coords))
        temp_coords -= s
    # Hessian gives us whether we're at a min or a max
    vals, _ = la.eig(terrain_hess(temp_coords))
    terrain_type = "peak" if vals[0] < 0 else "valley"
    temp_value = terrain_func(temp_coords)
    return (temp_coords, temp_value, terrain_type)

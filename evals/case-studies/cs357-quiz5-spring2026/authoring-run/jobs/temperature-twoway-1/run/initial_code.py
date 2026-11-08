import numpy as np
import numpy.linalg as la

def find_temperature_extreme(temperature_func, temperature_grad, temperature_hess, start_coords):
    # TODO:
    #   Use Newton's method on temperature_func to determine coordinates and temperature of its critical point
    #   Determine whether this critical point is a min (minimum), max (maximum), or saddle (saddle point)
    #   Return as tuple
    pass

## Use the following examples to help debugging your function
## We will test your code using different functions

# ## EXAMPLE 1
# def func1(xyz):
#     return xyz[0]**2 + xyz[1]**2 + xyz[2]**2
# def func1_grad(xyz):
#     return np.array([2*xyz[0], 2*xyz[1], 2*xyz[2]])
# def func1_hess(xyz):
#     return np.array([[2, 0, 0],[0, 2, 0],[0, 0, 2]])
# print(find_temperature_extreme(func1, func1_grad, func1_hess, np.array([1., 1., 1.])))
# # the output should be
# # (np.array([0, 0, 0]), 0, "min")

# ## EXAMPLE 2
# def func2(xyz):
#     return -(xyz[0]+1)**2 - 2*(xyz[1]-5)**2 - xyz[2]**2 + 100
# def func2_grad(xyz):
#     return np.array([-2*(xyz[0]+1), -4*(xyz[1]-5),  -2*xyz[2]])
# def func2_hess(xyz):
#     return np.array([[-2,  0,  0], [ 0, -4,  0], [ 0,  0, -2]])
# print(find_temperature_extreme(func2, func2_grad, func2_hess, np.array([0., 4., 1.])))
# # the output should be
# # (np.array([-1, 5, 0]), 100, "max")

# ## EXAMPLE 3
# def func3(xyz):
#     return -(xyz[0]+1)**2 + xyz[1]**2 - 1/3*(xyz[2]+3)**2 + 9
# def func3_grad(xyz):
#     return np.array([-2*(xyz[0]+1), 2*xyz[1],  -2/3*(xyz[2]+3)])
# def func3_hess(xyz):
#     return np.array([[-2, 0, 0], [0, 2, 0], [0, 0, -2/3]])
# print(find_temperature_extreme(func3, func3_grad, func3_hess, np.array([0., 4., 1.])))
# # the output should be
# # (np.array([-1, 0, -3]), 9, "saddle")
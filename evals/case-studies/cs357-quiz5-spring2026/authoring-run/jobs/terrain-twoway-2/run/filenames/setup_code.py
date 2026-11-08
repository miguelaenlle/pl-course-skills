import numpy as np
import numpy.linalg as la
import sympy as sp

# Setup Code
rng = np.random.default_rng()
x, y, z = sp.symbols('x y z')


def generate_terrain_func(coef_signs=(1, 1, 1)):
    # Generate a quadratic form with random positive coefficients and offsets
    a, b, c = [sp.Rational(rng.integers(1, 50), rng.integers(1, 15)) * coef_signs[i] for i in range(3)]
    e, f, g = rng.integers(1, 4, 3) * 2
    k, m, n = [sp.Rational(rng.integers(-1000, 1000), rng.integers(10, 100)) for _ in range(3)]
    q, r, s = [sp.Rational(rng.integers(1, 50), rng.integers(1, 15)) * coef_signs[i] for i in range(3)]
    o = sp.Rational(rng.integers(-1000, 1000), rng.integers(1, 100))

    f = a*(x+k)**e + b*(y+m)**f + c*(z+n)**g + q*(x+k)**2 + r*(y+m)**2 + s*(z+n)**2 + o
    
    np_shifts = np.array([float(k), float(m), float(n)])
    start_coords = rng.uniform(7, 15, 3) * rng.choice([-1, 1]) + np_shifts

    # Calculate gradient and hessian and convert everything to numpy
    eval_f = sp.lambdify((x, y, z), f)
    func_f = lambda X: eval_f(*X)
    grad = sp.Matrix([f.diff(var) for var in (x, y, z)])
    eval_grad = sp.lambdify((x, y, z), grad)
    func_grad = lambda X: eval_grad(*X)[:, 0]
    hess = sp.Matrix([grad.diff(var) for var in (x, y, z)])
    eval_hess = sp.lambdify((x, y, z), hess)
    func_hess = lambda X: eval_hess(*X).reshape((-1, 3))

    return func_f, func_grad, func_hess, start_coords


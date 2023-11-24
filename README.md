# mcst
MATLAB concrete syntax tree

Current stage:
+ [x] Bootstrap (via transpile to Python)
+ [ ] Fully compatible with standard MATLAB
+ [ ] Fully tested
+ [ ] Production ready

Known limitations:
+ Ellipses are not supported (working in progress)
  ```MATLAB
  some = fun(args, arg2, ...
             arg3, arg4, arg5)
  ```
+ Command format not supported (working in progress)
  ```MATLAB
  hold on
  ```
+ Exclamation point are not supported (working in progress)
  ```MATLAB
  !mkdir a
  ```
+ Multiple inheritance is not supported (low priority)
  ```MATLAB
  classdef A < B & C
  ```
+ Calling a parent class function of the same name from a subclass is not supported (low priority)
  ```MATLAB
  obj@ParentCls.fun()
  ```

Roadmap: 
+ [ ] Build auto-formatter tool
+ [ ] Support ellipses
+ [ ] Support command format
+ [ ] Support exclamation point
+ [ ] More test cases
+ [ ] Imporve performance

for more information about concrete syntax tree, see:

[https://github.com/psf/black/tree/main/src/blib2to3]()

[https://libcst.readthedocs.io/en/latest/why_libcst.html]()


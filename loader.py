import pyximport
pyximport.install()
import nvfbc


print(dir(nvfbc))
print(nvfbc.NvFBC().runtime_version)

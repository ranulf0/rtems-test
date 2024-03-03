This example loads objects at runtime and calls the symbols obj0 and obj1. 

The application provides the objects via tar filesystem, load the objects via `dlopen()` and then the symbols are called via `shell-script`

There are two ways to run this application:
- Loading the obj0.o and obj1.o
- Loading a relocatable object created from the obj0.o and obj1.o

To select which objects will be load, the `#if` value can be changed before building:
https://github.com/ranulf0/rtems-test/blob/main/init.c#L105


## Build and run
(qemu-system-arm) [arm/xilinx_zynq_a9_qemu]
```bash
make clean a9 run-a9
```
*it is also possible to build for i686, rpi4 and leon3*

## Output
Loading obj0.o and obj1.o (obj1 messages shall be lowercase)
```
1: rtl sym
 /mnt/obj0.o
    obj0 = 0x638f61
 /mnt/obj1.o
    obj1 = 0x6393b1
2: rtl call obj0
[obj0]
THIS MESSAGE IS FROM: obj0
ANOTHER MSG: 0
ONE MORE MESSAGE TO TEST OBJ0!
3: rtl call obj1
[obj1]
this message is from: obj1
another msg: 1
one more message to test obj1!
```

Loading the relocatable object
```
1: rtl sym
 /mnt/relocatable.obj
    obj0 = 0x6390b1
    obj1 = 0x639101
2: rtl call obj0
[obj0]
this message is from: obj0
ANOTHER MSG: 0
ONE MORE MESSAGE TO TEST OBJ0!
3: rtl call obj1
[obj1]
this message is from: obj1
ANOTHER MSG: 0
ONE MORE MESSAGE TO TEST OBJ0!
```

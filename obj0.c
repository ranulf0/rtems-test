#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void obj0 (void) {

    printf ("[%s]\n", __func__);
    printf ("%s: %s\n", "THIS MESSAGE IS FROM", __func__);
    printf ("%s\n", "ANOTHER MSG: 0");
    printf ("%s\n", "ONE MORE MESSAGE TO TEST OBJ0!");

    return;
}

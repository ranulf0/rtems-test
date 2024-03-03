#include <stdio.h>
#include <stdlib.h>
#include <string.h>

void obj1 (void) {

    printf ("[%s]\n", __func__);
    printf ("%s: %s\n", "this message is from", __func__);
    printf ("%s\n", "another msg: 1");
    printf ("%s\n", "one more message to test obj1!");

    return;
}

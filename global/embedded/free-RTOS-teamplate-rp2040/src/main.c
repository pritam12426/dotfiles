#include <stdio.h>

#include "CmakeConfig.h"
#include "pico/stdlib.h"

int main() {
	stdio_init_all();  // Initialize standard I/O
	while (true) {
		printf(
		    "Your prject \"%s\" --version \"%s\". Dis-[ %s ] is ready to.\nURL -- "
		    "%s\n",
		    PROJECT_NAME,
		    PROJECT_VERSION,
		    PROJECT_DESCRIPTION,
		    PROJECT_HOMEPAGE_URL);

		sleep_ms(1000);  // Delay 1 second
	}
	return 0;
}


/*

#include "pico/cyw43_arch.h"
#include "pico/stdlib.h"

int main() {
  stdio_init_all();
  if (cyw43_arch_init()) {
    printf("Wi-Fi init failed");
    return -1;
  }
  while (true) {
    cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 1);
    sleep_ms(250);
    cyw43_arch_gpio_put(CYW43_WL_GPIO_LED_PIN, 0);
    sleep_ms(250);
  }
}

*/

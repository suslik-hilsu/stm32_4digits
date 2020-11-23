#include <stm32f4xx.h>

#include <stm32f4xx_ll_rcc.h>
#include <stm32f4xx_ll_system.h>
#include <stm32f4xx_ll_utils.h>
#include <stm32f4xx_ll_pwr.h>
#include <stm32f4xx_ll_gpio.h>
#include <stm32f4xx_ll_bus.h>

#pragma clang diagnostic push
#pragma ide diagnostic ignored "EndlessLoop"
static volatile uint32_t tickCount = 0;

extern "C" void SysTick_Handler() {
    tickCount++;
}

static void setupClocks() {
    LL_FLASH_SetLatency(LL_FLASH_LATENCY_5);
    while (LL_FLASH_GetLatency() != LL_FLASH_LATENCY_5);
    LL_PWR_SetRegulVoltageScaling(LL_PWR_REGU_VOLTAGE_SCALE1);

    LL_RCC_HSE_Enable();
    while(LL_RCC_HSE_IsReady() != 1);

    LL_RCC_PLL_ConfigDomain_SYS(LL_RCC_PLLSOURCE_HSE, LL_RCC_PLLM_DIV_4, 168, LL_RCC_PLLP_DIV_2);
    LL_RCC_PLL_Enable();
    while(LL_RCC_PLL_IsReady() != 1);

    LL_RCC_SetAHBPrescaler(LL_RCC_SYSCLK_DIV_1);
    LL_RCC_SetAPB1Prescaler(LL_RCC_APB1_DIV_4);
    LL_RCC_SetAPB2Prescaler(LL_RCC_APB2_DIV_2);

    LL_RCC_SetSysClkSource(LL_RCC_SYS_CLKSOURCE_PLL);
    while(LL_RCC_GetSysClkSource() != LL_RCC_SYS_CLKSOURCE_STATUS_PLL);

    LL_Init1msTick(168000000);
    LL_SetSystemCoreClock(168000000);

    NVIC_EnableIRQ(SysTick_IRQn);
    SysTick->CTRL |= SysTick_CTRL_TICKINT_Msk;
}

static void setupGpio() {
    LL_AHB1_GRP1_EnableClock(LL_AHB1_GRP1_PERIPH_GPIOD);

    LL_GPIO_InitTypeDef gpio = { 0 };
    gpio.Pin = LL_GPIO_PIN_12 | LL_GPIO_PIN_13 | LL_GPIO_PIN_14 | LL_GPIO_PIN_15;
    gpio.Mode = LL_GPIO_MODE_OUTPUT;
    gpio.OutputType = LL_GPIO_OUTPUT_PUSHPULL;
    gpio.Pull = LL_GPIO_PULL_NO;
    gpio.Speed = LL_GPIO_SPEED_FREQ_HIGH;
    LL_GPIO_Init(GPIOD, &gpio);
}

static void delay(uint32_t millis) {
    uint32_t deadline = tickCount + millis;
    while (tickCount < deadline) __WFE();
}

int main() {
    setupClocks();
    setupGpio();

    while (1) {
        GPIOD->BSRR = LL_GPIO_PIN_12;
        delay(1000);
        GPIOD->BSRR = LL_GPIO_PIN_12 << 16;
        delay(1000);
    }
}
#pragma clang diagnostic pop
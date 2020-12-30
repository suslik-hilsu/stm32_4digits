#include <stm32f4xx.h>

#include <stm32f4xx_ll_rcc.h>
#include <stm32f4xx_ll_system.h>
#include <stm32f4xx_ll_utils.h>
#include <stm32f4xx_ll_pwr.h>
#include <stm32f4xx_ll_gpio.h>
#include <stm32f4xx_ll_bus.h>
#include <cmath>

#pragma clang diagnostic push
#pragma ide diagnostic ignored "EndlessLoop"
static volatile uint32_t tickCount = 0;

uint16_t diodesLocations[8] {14, 1, 3, 2, 13, 0, 15, 11};
uint8_t digits[11] {0b01110111, 0b00100100, 0b01011101, 0b01101101, 0b00101110, 0b01101011, 0b01111011, 0b00100101, 0b01111111, 0b01101111, 0b10000000};
uint16_t digitsLocations[4] {6, 7, 9, 8};
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
    LL_AHB1_GRP1_EnableClock(LL_AHB1_GRP1_PERIPH_GPIOC);
    LL_GPIO_InitTypeDef gpio = { 0 };
    gpio.Pin = (uint16_t)65535;
    gpio.Mode = LL_GPIO_MODE_OUTPUT;
    gpio.OutputType = LL_GPIO_OUTPUT_PUSHPULL;
    gpio.Pull = LL_GPIO_PULL_NO;
    gpio.Speed = LL_GPIO_SPEED_FREQ_HIGH;

    LL_GPIO_Init(GPIOC, &gpio);
}

static void delay(uint32_t millis) {
    uint32_t deadline = tickCount + millis;
    while (tickCount < deadline) __WFE();
}

int main() {
    setupClocks();
    setupGpio();

    int i, j;
    uint16_t digitInBits = 0;
    int ticks;
    int delay_time = 5;
    uint8_t current_digit;

    GPIOC->BSRR=65535;
    for(i = 0; i < 4; i++)
    {
        GPIOC->BSRR=(int)pow(2, digitsLocations[i])<<16;
    }

    while (tickCount <  12000) {
        ticks = tickCount;
        for(i = 0; i < 4; i++)
        {
            current_digit = digits[ticks%10];

            for(j = 0; j < 8; j++)
            {
                if((current_digit&1)==1)
                    digitInBits+=(uint16_t)pow(2, diodesLocations[j]);
                current_digit>>=1;
            }

            GPIOC->BSRR = digitInBits << 16;
            GPIOC->BSRR = pow(2, digitsLocations[i]);

            delay(delay_time);

            GPIOC->BSRR = digitInBits;
            GPIOC->BSRR = ((int)pow(2, digitsLocations[i])) << 16;
            digitInBits<<=16;
            ticks=ticks/10;
        }
    }
}
#pragma clang diagnostic pop
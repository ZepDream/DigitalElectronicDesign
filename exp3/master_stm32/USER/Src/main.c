/**
  ******************************************************************************
  * @file    main.c
  * @brief   实验三：STM32 作 SPI 主机，按 SPI 协议输出字符（每个字符 16 bit）
  * @note    课件作业的要求就是：新建 STM32F103 空工程，新增 SPI.c 和 SPI.h，
  *          新增 main.c，在 main.c 里用 SPI 接口循环输出字符，字符自己定义。
  *
  *          这里定义的 6 个字符，正好覆盖从机响应表的 4 种情况 + 2 个普通值：
  *              0x0000 -> 从机回 0x0123
  *              0x0004 -> 从机回 0x1234
  *              0x0008 -> 从机回 0x2345
  *              0x000A -> 从机回 0x3456
  *              0x0055 / 0x00AA -> 从机回 0xABAB
  *
  *          看结果的方法：Keil 里 Debug 运行，把 g_tx、g_rx 加到 Watch 窗口。
  *          g_tx 是本帧发出的字符，g_rx 是收回来的响应（是上一条字符的答案）。
  ******************************************************************************
  */

#include "stm32f10x.h"
#include "delay.h"
#include "spi.h"

/* 自定义字符表：每个字符 16 bit */
const u16 CHAR_TAB[] = { 0x0000, 0x0004, 0x0008, 0x000A, 0x0055, 0x00AA };
#define CHAR_NUM     (sizeof(CHAR_TAB) / sizeof(CHAR_TAB[0]))

/* 放到全局，方便在调试器里观察 */
u16 g_tx = 0;
u16 g_rx = 0;

int main(void)
{
    u8 i = 0;

    delay_init();                   /* SysTick 微秒延时，SPI 的半周期靠它 */
    SPI_GPIO_Init();                     /* 4 根 SPI 引脚初始化 */

    while (1)
    {
        g_tx = CHAR_TAB[i];
        g_rx = SPI_WriteRead(g_tx); /* 发出一个字符，同时收回从机的响应 */

        i = (u8)((i + 1) % CHAR_NUM);
        delay_ms(200);              /* 慢一点，方便用逻辑分析仪看波形 */
    }
}

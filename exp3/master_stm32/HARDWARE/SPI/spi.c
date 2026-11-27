/**
  ******************************************************************************
  * @file    spi.c
  * @brief   软件 SPI 主机：引脚初始化 + 一个 16 位收发函数
  * @note    时序（16 位、MSB first、SCK 空闲为高）：
  *
  *            CS   ----+_________________________________+----
  *                    |          (低电平期间传 16 位)    |
  *            SCK  -----+ +---+   +---+           +---+ +-----
  *                      | |   |   |   |    ...    |   | |
  *                      +-+   +---+   +---+       +-+   +-
  *                       ^     ^
  *                       |     每一位：下降沿从机采样 MOSI，主机同时采样 MISO
  *                       主机在 SCK 为高的时候把下一位摆到 MOSI 上
  *
  *          为什么 MOSI 要在 SCK 为高时摆好：从机是用 50 MHz 时钟去检测
  *          SCK 边沿的，它“看到”下降沿的时刻比主机真正拉低晚 2 个时钟
  *          （40 ns）。如果边沿和数据同时变，从机会采到下一位。
  ******************************************************************************
  */

#include "spi.h"
#include "delay.h"

/**
  * @brief  初始化 4 根引脚，并把总线置为空闲（CS = 1、SCK = 1）
  * @note   PC13/PC14/PC15 是后备域引脚，当普通 GPIO 用没问题，但驱动能力弱
  *         （数据手册限制 2 MHz），所以 SCK 只跑到 200 kHz 左右。
  */
void SPI_GPIO_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStructure;

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOC, ENABLE);

    /* CS / SCK / MOSI：推挽输出 */
    GPIO_InitStructure.GPIO_Pin   = SPI_CS_PIN | SPI_SCK_PIN | SPI_MOSI_PIN;
    GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_2MHz;
    GPIO_Init(SPI_CS_PORT, &GPIO_InitStructure);

    /* MISO：上拉输入（从机没上电时读回 1，一眼能看出“没接”） */
    GPIO_InitStructure.GPIO_Pin  = SPI_MISO_PIN;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;
    GPIO_Init(SPI_MISO_PORT, &GPIO_InitStructure);

    SPI_CS_H();
    SPI_SCK_H();
    SPI_MOSI_L();
}

/**
  * @brief  收发一个 16 位字符（写的同时把从机的响应读回来）
  * @param  tx_dat：要发出去的字符
  * @retval 从机返回的字符
  * @note   SPI 是全双工的：主机移出一位、同时移入一位。从机要等 CS 上升、
  *         16 位收齐才知道该回什么，所以本帧读到的是“上一帧命令”的响应。
  */
u16 SPI_WriteRead(u16 tx_dat)
{
    u16 rx_dat = 0;
    u8  i;

    SPI_CS_L();                     /* 帧开始 */
    delay_us(SPI_DELAY_US);         /* 等从机把输出移位寄存器装好 */

    for (i = 0; i < 16; i++)
    {
        /* 1. SCK 还是高：先把这一位摆到 MOSI 上 */
        if (tx_dat & 0x8000)
            SPI_MOSI_H();
        else
            SPI_MOSI_L();
        tx_dat <<= 1;
        delay_us(SPI_DELAY_US);

        /* 2. 下降沿：从机采样 MOSI，主机同时采样 MISO */
        SPI_SCK_L();
        rx_dat = (u16)((rx_dat << 1) | SPI_MISO);
        delay_us(SPI_DELAY_US);

        /* 3. 上升沿：从机移位，准备送出下一位 */
        SPI_SCK_H();
    }

    delay_us(SPI_DELAY_US);
    SPI_CS_H();                     /* 帧结束，从机在 CS 上升沿锁存命令 */
    delay_us(SPI_GAP_US);

    return rx_dat;
}

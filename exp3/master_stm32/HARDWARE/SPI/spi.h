/**
  ******************************************************************************
  * @file    spi.h
  * @brief   软件 SPI 主机头文件（变量名 / 宏定义按课件第 4 页）
  * @note    课件里的写法：
  *              SPI_GPIO_BANK  +  SPI_Pin_MOSI / MISO / CS / SCK
  *              SPI_MOSI_1 / SPI_MOSI_0 / SPI_SCK_1 / SPI_SCK_0
  *              SPI_CS_1 / SPI_CS_0
  *          改板子只需要改这些宏，spi.c 和 main.c 不用动。
  *
  *          本实验实际连线（和 EPM240 板一致）：
  *              SPI_CS   PC13  -> CPLD IO61
  *              SPI_SCK  PC14  -> CPLD IO57
  *              SPI_MOSI PC15  -> CPLD IO55
  *              SPI_MISO PA0   <- CPLD IO53
  *          课件里四根线都在 GPIOA，我们这里 CS/SCK/MOSI 在 GPIOC、MISO 在 GPIOA，
  *          所以多加一个 SPI_MISO_BANK 宏，其余名字保持和课件一样。
  ******************************************************************************
  */

#ifndef __SPI_H
#define __SPI_H

#include "stm32f10x.h"

/*------------------------------ 引脚定义（课件写法） --------------------------*/
#define SPI_GPIO_BANK            GPIOC
#define SPI_Pin_MOSI             GPIO_Pin_15
#define SPI_Pin_MISO             GPIO_Pin_0
#define SPI_Pin_CS               GPIO_Pin_13
#define SPI_Pin_SCK              GPIO_Pin_14

/* MISO 单独占一个端口，课件里四根线同端口时用不到这个宏 */
#define SPI_MISO_BANK            GPIOA

#define RCC_APB2Periph_SPI_GPIO_BANK   RCC_APB2Periph_GPIOC
#define RCC_APB2Periph_SPI_MISO_BANK   RCC_APB2Periph_GPIOA

/*------------------------------ 电平操作（课件写法） --------------------------*/
#define SPI_MOSI_1    GPIO_SetBits(SPI_GPIO_BANK, SPI_Pin_MOSI)
#define SPI_SCK_1     GPIO_SetBits(SPI_GPIO_BANK, SPI_Pin_SCK)
#define SPI_CS_1      GPIO_SetBits(SPI_GPIO_BANK, SPI_Pin_CS)

#define SPI_MOSI_0    GPIO_ResetBits(SPI_GPIO_BANK, SPI_Pin_MOSI)
#define SPI_SCK_0     GPIO_ResetBits(SPI_GPIO_BANK, SPI_Pin_SCK)
#define SPI_CS_0      GPIO_ResetBits(SPI_GPIO_BANK, SPI_Pin_CS)

#define SPI_MISO      GPIO_ReadInputDataBit(SPI_MISO_BANK, SPI_Pin_MISO)

/*------------------------------ 时序参数 --------------------------------------*/
/* 半个 SCK 周期（微秒）：课件没写延时，真机上加上从机才采得稳，2us 约 200kHz */
#define SPI_DELAY_US    2
/* 两帧之间的间隔，方便在示波器上区分每一帧 */
#define SPI_GAP_US      20

/*------------------------------ 函数声明（课件写法） --------------------------*/
void     SPI_GPIO_Config(void);
void     SPI_WriteData(uint16_t Data);
uint16_t SPI_ReadData(void);
void     SPI_WriteMsg(uint16_t CD, uint16_t ByteAmt);
void     SPI_ReadMsg(uint16_t *Dat, uint16_t ByteAmt);

/* 早期把读写合在一个函数里的版本，留着对照用，目前没有被调用 */
/* u16 SPI_WriteRead(u16 tx_dat); */

#endif /* __SPI_H */

/**
  ******************************************************************************
  * @file    spi.h
  * @brief   软件 SPI 主机：引脚宏定义 + 两个函数
  * @note    不用 STM32 内部的 SPI 外设，直接用 4 个普通 GPIO 按 SPI 时序
  *          一位一位地收发（就是课件里的“软件 SPI”）。
  *
  *          引脚分配（与 EPM240 从机板连线一致）：
  *              SPI_CS   PC13   -> CPLD IO61
  *              SPI_SCK  PC14   -> CPLD IO57
  *              SPI_MOSI PC15   -> CPLD IO55
  *              SPI_MISO PA0    <- CPLD IO53
  *
  *          换板子时只改这一个文件里的宏，main.c 和 spi.c 不用动。
  ******************************************************************************
  */

#ifndef __SPI_H
#define __SPI_H

#include "stm32f10x.h"

/*------------------------------ 引脚定义 ------------------------------------*/
#define SPI_CS_PORT     GPIOC
#define SPI_CS_PIN      GPIO_Pin_13

#define SPI_SCK_PORT    GPIOC
#define SPI_SCK_PIN     GPIO_Pin_14

#define SPI_MOSI_PORT   GPIOC
#define SPI_MOSI_PIN    GPIO_Pin_15

#define SPI_MISO_PORT   GPIOA
#define SPI_MISO_PIN    GPIO_Pin_0

/*------------------------------ 电平操作 ------------------------------------*/
#define SPI_CS_H()      GPIO_SetBits(SPI_CS_PORT,   SPI_CS_PIN)
#define SPI_CS_L()      GPIO_ResetBits(SPI_CS_PORT, SPI_CS_PIN)

#define SPI_SCK_H()     GPIO_SetBits(SPI_SCK_PORT,   SPI_SCK_PIN)
#define SPI_SCK_L()     GPIO_ResetBits(SPI_SCK_PORT, SPI_SCK_PIN)

#define SPI_MOSI_H()    GPIO_SetBits(SPI_MOSI_PORT,   SPI_MOSI_PIN)
#define SPI_MOSI_L()    GPIO_ResetBits(SPI_MOSI_PORT, SPI_MOSI_PIN)

#define SPI_MISO        GPIO_ReadInputDataBit(SPI_MISO_PORT, SPI_MISO_PIN)

/*------------------------------ 时序参数 ------------------------------------*/
/* 半个 SCK 周期（微秒），取 2 时 SCK 约 200 kHz                          */
#define SPI_DELAY_US    2
/* 帧间 CS 高电平时间（微秒），方便示波器区分每一帧                        */
#define SPI_GAP_US      20

/*------------------------------ 函数声明 ------------------------------------*/
void SPI_GPIO_Init(void);
u16  SPI_WriteRead(u16 tx_dat);

#endif

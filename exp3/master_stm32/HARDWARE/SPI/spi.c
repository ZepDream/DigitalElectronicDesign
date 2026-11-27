/**
  ******************************************************************************
  * @file    spi.c
  * @brief   软件 SPI 主机：引脚初始化 + 写函数 / 读函数（按课件第 3～4 页）
  * @note    课件把“写”和“读”拆开：
  *              SPI_WriteData(uint16_t Data)   写一个 16 位数据
  *              SPI_ReadData(void)             读一个 16 位数据
  *              SPI_WriteMsg(CD, ByteAmt)      拉低 CS，写一帧，拉高 CS
  *              SPI_ReadMsg(Dat, ByteAmt)      拉低 CS，读一帧，拉高 CS
  *          这样初学者能看清一帧是怎么由 CS + 16 个 SCK 组成的。
  *
  *          时序：16 位、MSB first、SCK 空闲为高。
  *              SCK 下降沿：从机采样 MOSI，主机采样 MISO
  *              SCK 上升沿：从机移位，把下一位放到 MISO
  *
  *          课件代码里没有延时；真机上 CS/SCK/MOSI 是普通 GPIO，从机又是
  *          50 MHz 同步采样，所以每一步之间加 SPI_DELAY_US(2us)，SCK 约 200 kHz。
  ******************************************************************************
  */

#include "spi.h"
#include "delay.h"

/**
  * @brief  引脚初始化（课件里的 SPI_GPIO_Config）
  * @note   CS / SCK / MOSI 推挽输出，MISO 浮空输入。
  *         PC13/PC14/PC15 是后备域引脚，速度限制 2 MHz，所以 SCK 只跑到 200 kHz。
  */
void SPI_GPIO_Config(void)
{
    GPIO_InitTypeDef GPIO_InitStructure;

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_SPI_GPIO_BANK |
                           RCC_APB2Periph_SPI_MISO_BANK, ENABLE);

    /* CS / SCK / MOSI：推挽输出 */
    GPIO_InitStructure.GPIO_Pin   = SPI_Pin_MOSI | SPI_Pin_SCK | SPI_Pin_CS;
    GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_2MHz;
    GPIO_Init(SPI_GPIO_BANK, &GPIO_InitStructure);

    /* MISO：输入（课件用 GPIO_Mode_IN_FLOATING，这里用上拉，
       从机没上电时读到 1，一眼能看出“没接”） */
    GPIO_InitStructure.GPIO_Pin  = SPI_Pin_MISO;
    GPIO_InitStructure.GPIO_Mode = GPIO_Mode_IPU;
    GPIO_Init(SPI_MISO_BANK, &GPIO_InitStructure);

    SPI_CS_1;                   /* 空闲：CS = 1 */
    SPI_SCK_1;                  /* 空闲：SCK = 1 */
    SPI_MOSI_0;
}

/**
  * @brief  写函数（课件第 3 页：输出移位寄存器）
  * @param  Data：要发出去的 16 位数据
  * @note   先摆 MOSI，再让 SCK 由高变低（从机在下降沿采样），
  *         然后 SCK 拉高、Data 左移一位，准备下一位。
  */
void SPI_WriteData(uint16_t Data)
{
    unsigned char i;

    for (i = 16; i > 0; i--)
    {
        if (Data & 0x8000)
            SPI_MOSI_1;         // 输出数据
        else
            SPI_MOSI_0;

        delay_us(SPI_DELAY_US);

        SPI_SCK_0;              // 下降沿：从机采样 MOSI
        delay_us(SPI_DELAY_US);

        SPI_SCK_1;              // 上升沿：从机移位
        delay_us(SPI_DELAY_US);

        Data <<= 1;
    }
}

/**
  * @brief  读函数（课件第 3 页：输入移位寄存器）
  * @retval 读回来的 16 位数据
  * @note   课件里写成 `void SPI_ReadData(uint16_t Data)`，靠传进去的变量带结果；
  *         传值调用其实带不出来，所以这里改成返回值，函数名和循环结构不变。
  *         另外课件把 `Data<<=1;` 写在循环最后，会多移一次，这里挪到前面。
  */
uint16_t SPI_ReadData(void)
{
    unsigned char i;
    unsigned char rxd;
    uint16_t Data = 0;

    for (i = 16; i > 0; i--)
    {
        Data <<= 1;

        /* 从机在 SCK 上升沿把下一位送到 MISO，所以下降沿之前读刚好 */
        rxd = SPI_MISO;
        if (rxd == 1)
            Data |= 0x01;       // 读入数据

        delay_us(SPI_DELAY_US);

        SPI_SCK_0;              // 下降沿
        delay_us(SPI_DELAY_US);

        SPI_SCK_1;              // 上升沿：从机送出下一位
        delay_us(SPI_DELAY_US);
    }

    return Data;
}

/**
  * @brief  写一帧（课件里的 SPI_WriteMsg）
  * @param  CD      ：要发送的 16 位命令
  * @param  ByteAmt ：保留参数，和课件函数原型一致（本实验每次固定发 1 个 16 位数）
  * @note   课件里那一版从机需要 0x789A 帧头，本实验的 CPLD 从机只认 16 位，
  *         所以帧头那两行保留但注释掉，直接把 CD 发出去。
  */
void SPI_WriteMsg(uint16_t CD, uint16_t ByteAmt)
{
    uint16_t Cmd = 0x0000;
    (void)ByteAmt;              /* 避免“参数未使用”告警 */

    SPI_CS_0;
    delay_us(SPI_DELAY_US);     /* 等从机把输出移位寄存器装好 */

    /* SPI_WriteData(0x789A);  // 帧头标记：课件从机需要，本实验从机不用 */
    /* Cmd = (CD << 8) | ByteAmt; // 课件把命令和字节数拼起来，本实验 CD 已是完整 16 位 */
    Cmd = CD;
    SPI_WriteData(Cmd);

    SPI_MOSI_0;                 // 写完拉低输出
    SPI_CS_1;                   // 从机在 CS 上升沿锁存命令
    delay_us(SPI_GAP_US);
}

/**
  * @brief  读一帧（课件里的 SPI_ReadMsg）
  * @param  Dat    ：存放结果的数组
  * @param  ByteAmt ：要读多少个 16 位数据
  * @note   读也是独立的一帧：CS 拉低 → 16 个 SCK → CS 拉高。
  *         从机在 CS 拉低时已经把“上一帧命令的响应”装进输出移位寄存器，
  *         所以读到的不是本帧命令的响应，而是上一条命令的响应。
  */
void SPI_ReadMsg(uint16_t *Dat, uint16_t ByteAmt)
{
    uint8_t i;

    SPI_CS_0;
    delay_us(SPI_DELAY_US);

    for (i = 0; i < ByteAmt; i++)
        Dat[i] = SPI_ReadData();

    SPI_CS_1;
    delay_us(SPI_GAP_US);
}

/*=============================================================================
  * 早期版本：把“写”和“读”合在一个函数里。集成度高，但看不出一帧是怎么拆开的，
  * 学习时不直观，所以整段保留为注释，供对照。现在 main.c 调用的是
  * SPI_WriteMsg() + SPI_ReadMsg() 两个函数。
  *-----------------------------------------------------------------------------
  * u16 SPI_WriteRead(u16 tx_dat)
  * {
  *     u16 rx_dat = 0;
  *     u8  i;
  *
  *     SPI_CS_0();
  *     delay_us(SPI_DELAY_US);
  *     for (i = 0; i < 16; i++)
  *     {
  *         if (tx_dat & 0x8000)
  *             SPI_MOSI_H();
  *         else
  *             SPI_MOSI_L();
  *         tx_dat <<= 1;
  *         delay_us(SPI_DELAY_US);
  *
  *         SPI_SCK_L();
  *         rx_dat = (u16)((rx_dat << 1) | SPI_MISO);
  *         delay_us(SPI_DELAY_US);
  *
  *         SPI_SCK_H();
  *     }
  *     delay_us(SPI_DELAY_US);
  *     SPI_CS_H();
  *     delay_us(SPI_GAP_US);
  *     return rx_dat;
  * }
  *============================================================================= */

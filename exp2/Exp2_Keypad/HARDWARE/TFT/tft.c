/**
  ******************************************************************************
  * @file    tft.c
  * @brief   ST7735S 1.8 inch TFT driver (software SPI, 16-bit RGB565)
  * @note    CLK=PB9  SDA=PB8  RS=PB7  RST=PB6  CS=PB5
  ******************************************************************************
  */

#include "tft.h"
#include "font.h"
#include "delay.h"

/* Some 1.8 inch ST7735S panels need a small GRAM offset. Keep 0 for MAR1801. */
#define TFT_X_OFFSET    0
#define TFT_Y_OFFSET    0

/*------------------------------- Pin macros ---------------------------------*/
#define TFT_CS_H()      (GPIOB->BSRR = GPIO_Pin_5)
#define TFT_CS_L()      (GPIOB->BRR  = GPIO_Pin_5)
#define TFT_RS_H()      (GPIOB->BSRR = GPIO_Pin_7)
#define TFT_RS_L()      (GPIOB->BRR  = GPIO_Pin_7)
#define TFT_RST_H()     (GPIOB->BSRR = GPIO_Pin_6)
#define TFT_RST_L()     (GPIOB->BRR  = GPIO_Pin_6)
#define TFT_CLK_H()     (GPIOB->BSRR = GPIO_Pin_9)
#define TFT_CLK_L()     (GPIOB->BRR  = GPIO_Pin_9)
#define TFT_SDA_H()     (GPIOB->BSRR = GPIO_Pin_8)
#define TFT_SDA_L()     (GPIOB->BRR  = GPIO_Pin_8)

_lcd_dev lcddev;
u16 POINT_COLOR = WHITE;
u16 BACK_COLOR  = BLACK;

/*----------------------------- Low level SPI --------------------------------*/
/* MSB first, mode 0: data is changed while CLK is low, sampled on rising edge */
static void TFT_SPI_WriteByte(u8 dat)
{
    u8 i;

    for(i = 0; i < 8; i++)
    {
        if(dat & 0x80)
        {
            TFT_SDA_H();
        }
        else
        {
            TFT_SDA_L();
        }
        dat <<= 1;
        TFT_CLK_H();
        TFT_CLK_L();
    }
}

static void TFT_WriteData16(u16 dat)
{
    TFT_SPI_WriteByte((u8)(dat >> 8));
    TFT_SPI_WriteByte((u8)dat);
}

static void LCD_WR_REG(u8 reg)
{
    TFT_CS_L();
    TFT_RS_L();
    TFT_SPI_WriteByte(reg);
    TFT_CS_H();
}

static void LCD_WR_DATA(u8 dat)
{
    TFT_CS_L();
    TFT_RS_H();
    TFT_SPI_WriteByte(dat);
    TFT_CS_H();
}

static void LCD_WriteReg(u8 reg, u8 dat)
{
    LCD_WR_REG(reg);
    LCD_WR_DATA(dat);
}

/*------------------------------- Panel reset ---------------------------------*/
void LCD_RESET(void)
{
    TFT_RST_L();
    delay_ms(50);
    TFT_RST_H();
    delay_ms(50);
}

/*--------------------------------- Init --------------------------------------*/
void LCD_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStructure;

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOB, ENABLE);

    GPIO_InitStructure.GPIO_Pin   = GPIO_Pin_5 | GPIO_Pin_6 | GPIO_Pin_7 |
                                    GPIO_Pin_8 | GPIO_Pin_9;
    GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOB, &GPIO_InitStructure);

    TFT_CS_H();
    TFT_RST_H();
    TFT_CLK_L();
    TFT_SDA_H();

    LCD_RESET();

    /*---------------- ST7735S power on sequence ----------------*/
    LCD_WR_REG(0x11);               /* sleep out */
    delay_ms(120);

    /* frame rate */
    LCD_WR_REG(0xB1);
    LCD_WR_DATA(0x01); LCD_WR_DATA(0x2C); LCD_WR_DATA(0x2D);
    LCD_WR_REG(0xB2);
    LCD_WR_DATA(0x01); LCD_WR_DATA(0x2C); LCD_WR_DATA(0x2D);
    LCD_WR_REG(0xB3);
    LCD_WR_DATA(0x01); LCD_WR_DATA(0x2C); LCD_WR_DATA(0x2D);
    LCD_WR_DATA(0x01); LCD_WR_DATA(0x2C); LCD_WR_DATA(0x2D);
    LCD_WR_REG(0xB4);               /* column inversion */
    LCD_WR_DATA(0x07);

    /* power sequence */
    LCD_WR_REG(0xC0);
    LCD_WR_DATA(0xA2); LCD_WR_DATA(0x02); LCD_WR_DATA(0x84);
    LCD_WR_REG(0xC1);
    LCD_WR_DATA(0xC5);
    LCD_WR_REG(0xC2);
    LCD_WR_DATA(0x0A); LCD_WR_DATA(0x00);
    LCD_WR_REG(0xC3);
    LCD_WR_DATA(0x8A); LCD_WR_DATA(0x2A);
    LCD_WR_REG(0xC4);
    LCD_WR_DATA(0x8A); LCD_WR_DATA(0xEE);
    LCD_WR_REG(0xC5);               /* VCOM */
    LCD_WR_DATA(0x0E);

    /* gamma */
    LCD_WR_REG(0xE0);
    LCD_WR_DATA(0x0F); LCD_WR_DATA(0x1A); LCD_WR_DATA(0x0F);
    LCD_WR_DATA(0x18); LCD_WR_DATA(0x2F); LCD_WR_DATA(0x28);
    LCD_WR_DATA(0x20); LCD_WR_DATA(0x22); LCD_WR_DATA(0x1F);
    LCD_WR_DATA(0x1B); LCD_WR_DATA(0x23); LCD_WR_DATA(0x37);
    LCD_WR_DATA(0x00); LCD_WR_DATA(0x07); LCD_WR_DATA(0x02);
    LCD_WR_DATA(0x10);
    LCD_WR_REG(0xE1);
    LCD_WR_DATA(0x0F); LCD_WR_DATA(0x1B); LCD_WR_DATA(0x0F);
    LCD_WR_DATA(0x17); LCD_WR_DATA(0x33); LCD_WR_DATA(0x2C);
    LCD_WR_DATA(0x29); LCD_WR_DATA(0x2E); LCD_WR_DATA(0x30);
    LCD_WR_DATA(0x30); LCD_WR_DATA(0x39); LCD_WR_DATA(0x3F);
    LCD_WR_DATA(0x00); LCD_WR_DATA(0x07); LCD_WR_DATA(0x03);
    LCD_WR_DATA(0x10);

    /* GRAM window: 0..127 x 0..159 */
    LCD_WR_REG(0x2A);
    LCD_WR_DATA(0x00); LCD_WR_DATA(0x00);
    LCD_WR_DATA(0x00); LCD_WR_DATA(0x7F);
    LCD_WR_REG(0x2B);
    LCD_WR_DATA(0x00); LCD_WR_DATA(0x00);
    LCD_WR_DATA(0x00); LCD_WR_DATA(0x9F);

    LCD_WR_REG(0xF0);               /* enable test command */
    LCD_WR_DATA(0x01);
    LCD_WR_REG(0xF6);               /* disable RAM power save */
    LCD_WR_DATA(0x00);
    LCD_WR_REG(0x3A);               /* 65K color, 16 bit/pixel */
    LCD_WR_DATA(0x05);
    LCD_WR_REG(0x29);               /* display on */
    delay_ms(20);

    LCD_direction(0);               /* portrait: 128 x 160 */
    LCD_Clear(BLACK);
}

/*------------------------------- Direction -----------------------------------*/
/* 0: portrait 128x160      1: landscape 160x128
   2: portrait 180 rotated  3: landscape 180 rotated                  */
void LCD_direction(u8 direction)
{
    lcddev.setxcmd = 0x2A;
    lcddev.setycmd = 0x2B;
    lcddev.wramcmd = 0x2C;

    switch(direction)
    {
        case 0:
            lcddev.width  = LCD_W;
            lcddev.height = LCD_H;
            LCD_WriteReg(0x36, (0 << 3) | (1 << 6) | (1 << 7));
            break;
        case 1:
            lcddev.width  = LCD_H;
            lcddev.height = LCD_W;
            LCD_WriteReg(0x36, (0 << 3) | (1 << 7) | (1 << 5));
            break;
        case 2:
            lcddev.width  = LCD_W;
            lcddev.height = LCD_H;
            LCD_WriteReg(0x36, (0 << 3) | (0 << 6) | (0 << 7));
            break;
        case 3:
            lcddev.width  = LCD_H;
            lcddev.height = LCD_W;
            LCD_WriteReg(0x36, (0 << 3) | (1 << 7) | (1 << 6) | (1 << 5));
            break;
        default:
            break;
    }
}

/*------------------------------- Window --------------------------------------*/
void LCD_SetWindows(u16 xStar, u16 yStar, u16 xEnd, u16 yEnd)
{
    xStar += TFT_X_OFFSET;
    xEnd  += TFT_X_OFFSET;
    yStar += TFT_Y_OFFSET;
    yEnd  += TFT_Y_OFFSET;

    LCD_WR_REG(lcddev.setxcmd);
    LCD_WR_DATA((u8)(xStar >> 8));
    LCD_WR_DATA((u8)(xStar & 0xFF));
    LCD_WR_DATA((u8)(xEnd >> 8));
    LCD_WR_DATA((u8)(xEnd & 0xFF));

    LCD_WR_REG(lcddev.setycmd);
    LCD_WR_DATA((u8)(yStar >> 8));
    LCD_WR_DATA((u8)(yStar & 0xFF));
    LCD_WR_DATA((u8)(yEnd >> 8));
    LCD_WR_DATA((u8)(yEnd & 0xFF));

    LCD_WR_REG(lcddev.wramcmd);     /* following bytes go to GRAM */
}

void LCD_SetCursor(u16 Xpos, u16 Ypos)
{
    LCD_SetWindows(Xpos, Ypos, Xpos, Ypos);
}

/*-------------------------------- Drawing ------------------------------------*/
void LCD_DrawPointColor(u16 x, u16 y, u16 color)
{
    if(x >= lcddev.width || y >= lcddev.height)
    {
        return;
    }

    LCD_SetWindows(x, y, x, y);
    TFT_CS_L();
    TFT_RS_H();
    TFT_WriteData16(color);
    TFT_CS_H();
}

void LCD_DrawPoint(u16 x, u16 y)
{
    LCD_DrawPointColor(x, y, POINT_COLOR);
}

void LCD_Fill(u16 x1, u16 y1, u16 x2, u16 y2, u16 color)
{
    u16 tmp;
    u32 total;

    if(x1 > x2) { tmp = x1; x1 = x2; x2 = tmp; }
    if(y1 > y2) { tmp = y1; y1 = y2; y2 = tmp; }
    if(x2 >= lcddev.width)  x2 = lcddev.width - 1;
    if(y2 >= lcddev.height) y2 = lcddev.height - 1;

    total = (u32)(x2 - x1 + 1) * (y2 - y1 + 1);

    LCD_SetWindows(x1, y1, x2, y2);
    TFT_CS_L();
    TFT_RS_H();
    while(total--)
    {
        TFT_WriteData16(color);
    }
    TFT_CS_H();
}

void LCD_Clear(u16 color)
{
    LCD_Fill(0, 0, lcddev.width - 1, lcddev.height - 1, color);
}

void LCD_DrawLine(u16 x1, u16 y1, u16 x2, u16 y2, u16 color)
{
    u16 t;
    int xerr = 0, yerr = 0, delta_x, delta_y, distance;
    int incx, incy, uRow, uCol;

    delta_x = (int)x2 - (int)x1;
    delta_y = (int)y2 - (int)y1;
    uRow = x1;
    uCol = y1;

    if(delta_x > 0)      incx = 1;
    else if(delta_x == 0) incx = 0;
    else                 { incx = -1; delta_x = -delta_x; }

    if(delta_y > 0)      incy = 1;
    else if(delta_y == 0) incy = 0;
    else                 { incy = -1; delta_y = -delta_y; }

    if(delta_x > delta_y) distance = delta_x;
    else                  distance = delta_y;

    for(t = 0; t <= distance; t++)
    {
        LCD_DrawPointColor((u16)uRow, (u16)uCol, color);
        xerr += delta_x;
        yerr += delta_y;
        if(xerr > distance)
        {
            xerr -= distance;
            uRow += incx;
        }
        if(yerr > distance)
        {
            yerr -= distance;
            uCol += incy;
        }
    }
}

void LCD_DrawRectangle(u16 x1, u16 y1, u16 x2, u16 y2, u16 color)
{
    LCD_DrawLine(x1, y1, x2, y1, color);
    LCD_DrawLine(x1, y1, x1, y2, color);
    LCD_DrawLine(x1, y2, x2, y2, color);
    LCD_DrawLine(x2, y1, x2, y2, color);
}

/*------------------------------- Text: ASCII --------------------------------*/
/* ASCII font: size 12 -> 6x12, size 16 -> 8x16. num is the ASCII code.
   mode = 0: background is overwritten by bc
   mode = 1: background is kept, only foreground pixels are drawn          */
void LCD_ShowChar(u16 x, u16 y, u16 fc, u16 bc, u8 num, u8 size, u8 mode)
{
    const unsigned char *font;
    u8 temp, pos, t, width, height;
    u16 color;

    if(num < ' ' || num > '~') return;

    if(size == 12)
    {
        font   = (const unsigned char *)asc2_1206;
        width  = 6;
        height = 12;
    }
    else if(size == 16)
    {
        font   = (const unsigned char *)asc2_1608;
        width  = 8;
        height = 16;
    }
    else
    {
        return;
    }

    if((x + width) > lcddev.width || (y + height) > lcddev.height) return;

    num -= ' ';

    if(mode == 0)
    {
        LCD_SetWindows(x, y, x + width - 1, y + height - 1);
        TFT_CS_L();
        TFT_RS_H();
        for(pos = 0; pos < height; pos++)
        {
            temp = font[(u16)num * height + pos];
            for(t = 0; t < width; t++)
            {
                color = (temp & 0x01) ? fc : bc;
                TFT_WriteData16(color);
                temp >>= 1;
            }
        }
        TFT_CS_H();
    }
    else
    {
        for(pos = 0; pos < height; pos++)
        {
            temp = font[(u16)num * height + pos];
            for(t = 0; t < width; t++)
            {
                if(temp & 0x01)
                {
                    LCD_DrawPointColor(x + t, y + pos, fc);
                }
                temp >>= 1;
            }
        }
    }
}

void LCD_ShowString(u16 x, u16 y, u16 fc, u16 bc, const char *p, u8 size, u8 mode)
{
    u8 width;

    if(size != 12 && size != 16) return;
    width = size / 2;

    while(*p >= ' ' && *p <= '~')
    {
        if((x + width) > lcddev.width || (y + size) > lcddev.height) return;
        LCD_ShowChar(x, y, fc, bc, (u8)(*p), size, mode);
        x += width;
        p++;
    }
}

/* Show an unsigned number with a fixed width (leading spaces). */
void LCD_ShowNum(u16 x, u16 y, u16 fc, u16 bc, u32 num, u8 len, u8 size)
{
    u8 t, temp, enshow = 0;
    u32 div;

    for(t = 0; t < len; t++)
    {
        div = 1;
        {
            u8 k;
            for(k = 0; k < (len - t - 1); k++) div *= 10;
        }
        temp = (u8)((num / div) % 10);

        if(enshow == 0 && t < (len - 1))
        {
            if(temp == 0)
            {
                LCD_ShowChar(x + t * (size / 2), y, fc, bc, ' ', size, 0);
                continue;
            }
            else
            {
                enshow = 1;
            }
        }
        LCD_ShowChar(x + t * (size / 2), y, fc, bc, (u8)(temp + '0'), size, 0);
    }
}

/*------------------------------- Text: Chinese -------------------------------*/
static const typFNT_GB12 *LCD_FindCN12(const u8 *p)
{
    u16 i;

    for(i = 0; i < (u16)TFONT12_NUM; i++)
    {
        if(tfont12[i].Index[0] == p[0] && tfont12[i].Index[1] == p[1])
        {
            return &tfont12[i];
        }
    }
    return 0;
}

static const typFNT_GB16 *LCD_FindCN16(const u8 *p)
{
    u16 i;

    for(i = 0; i < (u16)TFONT16_NUM; i++)
    {
        if(tfont16[i].Index[0] == p[0] && tfont16[i].Index[1] == p[1])
        {
            return &tfont16[i];
        }
    }
    return 0;
}

/* 12x12 Chinese glyph: 12 rows x 2 bytes, 6 pixels per byte, MSB = left */
static void LCD_DrawCNChar12(u16 x, u16 y, u16 fc, u16 bc,
                             const typFNT_GB12 *font, u8 mode)
{
    u8 i, j, temp;

    if((x + 12) > lcddev.width || (y + 12) > lcddev.height) return;

    if(mode == 0)
    {
        LCD_SetWindows(x, y, x + 11, y + 11);
        TFT_CS_L();
        TFT_RS_H();
        for(i = 0; i < 24; i++)
        {
            temp = font->Msk[i];
            for(j = 0; j < 6; j++)
            {
                TFT_WriteData16((temp & 0x80) ? fc : bc);
                temp <<= 1;
            }
        }
        TFT_CS_H();
    }
    else
    {
        for(i = 0; i < 24; i++)
        {
            temp = font->Msk[i];
            for(j = 0; j < 6; j++)
            {
                if(temp & 0x80)
                {
                    LCD_DrawPointColor(x + (i & 0x01) * 6 + j, y + (i >> 1), fc);
                }
                temp <<= 1;
            }
        }
    }
}

/* 16x16 Chinese glyph: 16 rows x 2 bytes, 8 pixels per byte, MSB = left */
static void LCD_DrawCNChar16(u16 x, u16 y, u16 fc, u16 bc,
                             const typFNT_GB16 *font, u8 mode)
{
    u8 i, j, temp;

    if((x + 16) > lcddev.width || (y + 16) > lcddev.height) return;

    if(mode == 0)
    {
        LCD_SetWindows(x, y, x + 15, y + 15);
        TFT_CS_L();
        TFT_RS_H();
        for(i = 0; i < 32; i++)
        {
            temp = font->Msk[i];
            for(j = 0; j < 8; j++)
            {
                TFT_WriteData16((temp & 0x80) ? fc : bc);
                temp <<= 1;
            }
        }
        TFT_CS_H();
    }
    else
    {
        for(i = 0; i < 32; i++)
        {
            temp = font->Msk[i];
            for(j = 0; j < 8; j++)
            {
                if(temp & 0x80)
                {
                    LCD_DrawPointColor(x + (i & 0x01) * 8 + j, y + (i >> 1), fc);
                }
                temp <<= 1;
            }
        }
    }
}

/* Mixed Chinese (GB2312, 2 bytes) + ASCII string. size = 12 or 16. */
void LCD_ShowChinese(u16 x, u16 y, u16 fc, u16 bc, const char *p, u8 size, u8 mode)
{
    const typFNT_GB12 *f12;
    const typFNT_GB16 *f16;
    const u8 *s = (const u8 *)p;
    u8 width;

    if(size != 12 && size != 16) return;
    width = size / 2;

    while(*s)
    {
        if(*s < 0x80)
        {
            if((x + width) > lcddev.width) break;
            LCD_ShowChar(x, y, fc, bc, *s, size, mode);
            x += width;
            s++;
        }
        else
        {
            if(s[1] == 0) break;
            if((x + size) > lcddev.width) break;

            if(size == 12)
            {
                f12 = LCD_FindCN12(s);
                if(f12 != 0)
                {
                    LCD_DrawCNChar12(x, y, fc, bc, f12, mode);
                }
            }
            else
            {
                f16 = LCD_FindCN16(s);
                if(f16 != 0)
                {
                    LCD_DrawCNChar16(x, y, fc, bc, f16, mode);
                }
            }
            x += size;
            s += 2;
        }
    }
}

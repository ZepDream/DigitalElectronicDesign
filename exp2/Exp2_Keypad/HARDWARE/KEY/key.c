/**
  ******************************************************************************
  * @file    key.c
  * @brief   4x4 matrix keypad scan (row drive low, column read with pull-up)
  * @note    Row order   : KEY8(PA7), KEY7(PA6), KEY6(PA5), KEY5(PA4)
  *          Column order: KEY4(PB11), KEY3(PB10), KEY2(PB1), KEY1(PB0)
  *          key index   = row * 4 + column, giving 0..F row by row
  ******************************************************************************
  */

#include "key.h"
#include "delay.h"

#define ROW_ALL     (GPIO_Pin_4 | GPIO_Pin_5 | GPIO_Pin_6 | GPIO_Pin_7)
#define COL_ALL     (GPIO_Pin_0 | GPIO_Pin_1 | GPIO_Pin_10 | GPIO_Pin_11)

/* PA7, PA6, PA5, PA4 = row 0..3 */
static const u16 key_row_pin[4] = {GPIO_Pin_4, GPIO_Pin_5, GPIO_Pin_6, GPIO_Pin_7};

/* PB11, PB10, PB1, PB0 = column 0..3 */
static const u16 key_col_pin[4] = {GPIO_Pin_0, GPIO_Pin_1, GPIO_Pin_10, GPIO_Pin_11};

/* Key labels shown on the LCD */
static const char key_char[KEY_NUM] =
{
    '0', '1', '2', '3',
    '4', '5', '6', '7',
    '8', '9', 'A', 'B',
    'C', 'D', 'E', 'F'
};

/* All rows high: no row is driven low, keypad consumes no current */
static void KEY_RowsHigh(void)
{
    GPIOA->BSRR = ROW_ALL;
}

/* Read the four column lines, bit j = 1 means column j is low (pressed) */
static u8 KEY_ReadCols(void)
{
    u8 j;
    u8 mask = 0;

    for(j = 0; j < 4; j++)
    {
        if(GPIO_ReadInputDataBit(GPIOB, key_col_pin[j]) == Bit_RESET)
        {
            mask |= (u8)(1u << j);
        }
    }

    return mask;
}

void KEY_Init(void)
{
    GPIO_InitTypeDef GPIO_InitStructure;

    RCC_APB2PeriphClockCmd(RCC_APB2Periph_GPIOA | RCC_APB2Periph_GPIOB, ENABLE);

    /* Rows: push-pull output, idle high */
    GPIO_InitStructure.GPIO_Pin   = ROW_ALL;
    GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_Out_PP;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOA, &GPIO_InitStructure);
    KEY_RowsHigh();

    /* Columns: input with internal pull-up; pressed key pulls the line low */
    GPIO_InitStructure.GPIO_Pin   = COL_ALL;
    GPIO_InitStructure.GPIO_Mode  = GPIO_Mode_IPU;
    GPIO_InitStructure.GPIO_Speed = GPIO_Speed_50MHz;
    GPIO_Init(GPIOB, &GPIO_InitStructure);
}

/* Fast check: drive all rows low and see whether any column is pulled low */
u8 KEY_IsPressed(void)
{
    u8 mask;

    GPIOA->BRR = ROW_ALL;
    delay_us(50);
    mask = KEY_ReadCols();
    KEY_RowsHigh();

    return (mask != 0) ? 1 : 0;
}

char KEY_GetChar(u8 key)
{
    if(key < KEY_NUM)
    {
        return key_char[key];
    }

    return '?';
}

/*
 * Scan one key press:
 *   1. drive row 0..3 low in turn and read the columns;
 *   2. once a low column is found, wait 10 ms and confirm it;
 *   3. wait until all keys are released, so one press returns once.
 * Returns 0..15, or KEY_NONE.
 */
u8 KEY_Scan(void)
{
    u8 row, col, mask, key;

    for(row = 0; row < 4; row++)
    {
        KEY_RowsHigh();
        GPIOA->BRR = key_row_pin[row];
        delay_us(50);
        mask = KEY_ReadCols();
        KEY_RowsHigh();

        if(mask == 0)
        {
            continue;
        }

        /* Debounce: check the same row again after 10 ms */
        delay_ms(10);
        GPIOA->BRR = key_row_pin[row];
        delay_us(50);
        mask = KEY_ReadCols();
        KEY_RowsHigh();

        if(mask == 0)
        {
            continue;
        }

        for(col = 0; col < 4; col++)
        {
            if(mask & (u8)(1u << col))
            {
                key = (u8)(row * 4 + col);

                /* Wait for release: a press is reported only once */
                while(KEY_IsPressed())
                {
                    delay_ms(10);
                }

                return key;
            }
        }
    }

    return KEY_NONE;
}

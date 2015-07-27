#include "main.h"
static USART_HandleTypeDef usart2;

void retarget_init()
{
  // Initialize UART
  usart2.Instance = USARTx;
  usart2.Init.BaudRate = 115200;
  usart2.Init.WordLength   = UART_WORDLENGTH_8B;
  usart2.Init.StopBits     = UART_STOPBITS_1;
  usart2.Init.Parity       = UART_PARITY_NONE;
  usart2.Init.Mode         = UART_MODE_TX_RX;
  HAL_USART_Init(&usart2);
}

int _write (int fd, char *ptr, int len)
{
  /* Write "len" of char from "ptr" to file id "fd"
   * Return number of char written.
   * Need implementing with UART here. */
   HAL_USART_Transmit(&usart2, ptr, len, 0xFFFF);
  return len;
}

int _read (int fd, char *ptr, int len)
{
  /* Read "len" of char to "ptr" from file id "fd"
   * Return number of char read.
   * Need implementing with UART here. */
  return len;
}

void _ttywrch(int ch) {
  /* Write one char "ch" to the default console
   * Need implementing with UART here. */
  HAL_USART_Transmit(&usart2, (uint8_t*)&ch, 1, 0xFFFF);
}



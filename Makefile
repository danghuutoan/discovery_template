PROJECT = $(notdir $(CURDIR))
COMPILER = arm-none-eabi-

CC		= $(COMPILER)gcc
CP		= $(COMPILER)objcopy
AS		= $(COMPILER)as
LD 		= $(COMPILER)ld
OD		= $(COMPILER)objdump
SIZE    = $(COMPILER)size

DEF+=USE_FULL_ASSERT
DEF+=USE_HAL_DRIVER
DEF+=STM32F407xx
DEF+=HSE_VALUE=8000000
DEF+=___FPU_USED=1
DEF+=___FPU_PRESENT=1

ifeq ($(HARDFP),1)
	FLOAT_ABI = hard
else
	FLOAT_ABI = softfp
endif
CPU = -mthumb -mcpu=cortex-m4 -mfpu=fpv4-sp-d16 -mfloat-abi=softfp 

HAL_DRIVER 	= 	Drivers/STM32F4xx_HAL_Driver
CMSIS		=   Drivers/CMSIS
BSP			=   Drivers/BSP/STM32F4-Discovery
STM32F4xx 	= 	$(CMSIS)/Device/ST/STM32F4xx

VPATH= $(HAL_DRIVER)/Src:$(BSP):$(STM32F4xx)/Source:Src

INC+= $(HAL_DRIVER)/Inc
INC+= $(BSP)
INC+= $(STM32F4xx)/Include 
INC+= $(CMSIS)/Include
INC+= Inc


SRC+= system_stm32f4xx.c
SRC+= main.c
SRC+= stm32f4xx_hal_msp.c
SRC+= stm32f4xx_it.c 
SRC+= stm32f4xx_hal.c
SRC+= stm32f4xx_hal_cortex.c
SRC+= stm32f4xx_hal_dma.c
SRC+= stm32f4xx_hal_rcc.c
SRC+= stm32f4xx_hal_gpio.c
SRC+= stm32f4xx_hal_usart.c
SRC+= retarget.c


STARTUP= GCC-ARM/startup_stm32f407xx.s

LDSCRIPT= GCC-ARM/STM32F4-Discovery/STM32F407VG_FLASH.ld

LINKER = $(patsubst %,-T%,$(LDSCRIPT))
INCLUDE= $(patsubst %,-I%,$(INC))
DEFINE = $(patsubst %,-D%,$(DEF))

OUTPUT 	= GCC-ARM/Output
DEPDIR 	= GCC-ARM/Dependencies

$(shell mkdir -p $(OUTPUT))
$(shell mkdir -p $(DEPDIR))


df = $(DEPDIR)/$(*F)

OBJS+=$(patsubst %.c,%.o,$(SRC))
OBJS+=$(patsubst %.s,%.o,$(STARTUP))
OBJECTS = $(addprefix $(OUTPUT)/, $(OBJS))

CFLAGS+=$(INCLUDE)
CFLAGS+=$(DEFINE)
CFLAGS+=-g
CFLAGS+=$(CPU)
CFLAGS+=-MD

LDFLAGS+=$(LINKER)
LDFLAGS+=$(CPU) -Wl,--gc-sections --specs=nano.specs -u _printf_float -u _scanf_float  -Wl,-Map=$(PROJECT).map,--cref

LDFLAGS+=$(CFLAGS)
#LDFLAGS+=-lrdimon
#LDFLAGS+=--specs=rdimon.specs
#Don't use semihosting
LDFLAGS+=--specs=nosys.specs
#use newlib nano
#LDFLAGS+=--specs=nano.specs 
LDFLAGS+=-lnosys
LDFLAGS+=-lgcc
LDFLAGS+=-lm
LDFLAGS+=-lc
LDFLAGS+=-lg

ASFLAGS+=-g
ASFLAGS+=$(CPU)

$(OUTPUT)/%.o: %.s Makefile
	@mkdir -p $(@D)
	@$(AS) $(ASFLAGS) -mthumb $< -o $@
	@echo "AS ${@}"
$(OUTPUT)/%.o: %.c Makefile
	@mkdir -p $(@D)
	@$(CC) $(CFLAGS) -std=gnu99 -c $< -o $@
	@echo "CC ${@}"
	@cp $(OUTPUT)/$*.d $(df).P; \
	sed -e 's/#.*//' -e 's/^[^:]*: *//' -e 's/ *\\$$//' \
	-e '/^$$/ d' -e 's/$$/ :/' < $(OUTPUT)/$*.d >> $(df).P; \
	rm -f $(OUTPUT)/$*.d



all: $(PROJECT).elf $(PROJECT).bin size

$(PROJECT).elf : $(OBJECTS)
	@mkdir -p $(@D)
	@$(CC) $^ $(LDFLAGS) $(LIBS) -o $@
	@echo "LD ${@}"
$(PROJECT).bin : $(PROJECT).elf
	@mkdir -p $(@D)
	@$(CP) -O binary $(PROJECT).elf $(PROJECT).bin
	@echo "CP ${@}"

size: $(PROJECT).elf
	@$(SIZE) $(PROJECT).elf
	
clean: 
	@rm -f $(OBJECTS) $(PROJECT).bin $(DEPDIR)/*.P $(PROJECT).elf
flash:
	@st-flash --reset write $(PROJECT).bin 0x8000000

-include $(SRC:%.c=$(DEPDIR)/%.P)

	icl 'symbols.asm'

CHARSET_SIZE  = $0400
PALETTE_SIZE  = $0200

VRAM_CHARSET   = VRAM
VRAM_PAL_ATARI = VRAM + CHARSET_SIZE
VRAM_PAL_ZX    = VRAM_PAL_ATARI + PALETTE_SIZE

VRAM_SCREEN    = VRAM_PAL_ZX + PALETTE_SIZE

TEXT_SCREEN_SIZE       = 40*24
TEXT_SCREEN_SIZE_WIDE  = 20*24
TEXT_SCREEN_SIZE_BLOCK = 20*12
TEXT_SCREEN_DLIST_SIZE = 32


	org $FFFA

   .word nmi
	.word boot
	.word irq

	org OS_CALL
init:	
	pha
	txa
	asl
	tax
	mwa os_vector_table,x OS_VECTOR
	pla
	jmp (OS_VECTOR)
	
boot:
   lda #0
   sta VSTATUS
   sta CHRONI_ENABLED

; init interrupt vectors
   
   ldx #0
copy_vector:
   lda interrupt_vectors, x
   sta NMI_VECTOR, x
   inx
   cpx #$0C
   bne copy_vector
	
	mwa #copy_params_charset COPY_PARAMS
	jsr copy_block_with_params
	
   mwa #copy_params_pal_atari COPY_PARAMS
	jsr copy_block_with_params
	
	mwa #copy_params_pal_spectrum COPY_PARAMS
	jsr copy_block_with_params
	
	lda #$ff
	jsr set_video_mode
	
	lda #1
	sta CHRONI_ENABLED
	lda VSTATUS
	ora #VSTATUS_EN_INTS
	sta VSTATUS
	
	jmp BOOTADDR

interrupt_vectors:
   .word nmi_os
   .word irq_os
   .word hblank_os
   .word vblank_os
   .word hblank_user
   .word vblank_user

nmi_os:
   cld
   pha
   lda VSTATUS
   ror
   bcc nmi_check_hblank
   pla
   jmp (VBLANK_VECTOR)
nmi_check_hblank:
   ror
   bcc nmi_done
   pla
   jmp (HBLANK_VECTOR)
nmi_done:
   pla
   rti

irq_os:
   rti

hblank_os:
   jsr call_hblank_user
   rti
   
vblank_os:
   pha
   adw FRAMECOUNT #1
   
   lda CHRONI_ENABLED
   beq set_chroni_disabled
   lda VSTATUS
   ora #VSTATUS_ENABLE
   sta VSTATUS
   bne chroni_enabled_set
set_chroni_disabled:
   lda VSTATUS
   and #($FF - VSTATUS_ENABLE)
   sta VSTATUS
chroni_enabled_set:   
   jsr call_vblank_user
   pla
   rti

vblank_user:
   rts   

hblank_user:
   rts   
   
call_vblank_user:
   jmp (VBLANK_VECTOR_USER)

call_hblank_user:
   jmp (HBLANK_VECTOR_USER)
    
set_video_mode:
   pha
   jsr set_video_disabled
   pla
	cmp #$ff
	beq set_video_mode_off
	jmp set_video_mode_std
	rts
	
set_video_mode_off:
	ldx #0
	lda #112
create_dl_mode_off:	
	sta VRAM_SCREEN, x
	inx
	cpx #24
	bne create_dl_mode_off
	lda #$41
	sta VRAM_SCREEN, x
	
	jmp set_video_mode_dl
	
os_vector_table
	.word set_video_mode
	.word copy_block
	.word copy_block_with_params
	.word mem_set_bytes
	.word ram2vram
	.word vram2ram
	.word vram_set_bytes

copy_params_charset:
	.word charset, VRAM_CHARSET, CHARSET_SIZE
copy_params_pal_atari:
	.word atari_palette_ntsc, VRAM_PAL_ATARI, PALETTE_SIZE
copy_params_pal_spectrum:
	.word spectrum_palette,   VRAM_PAL_ZX, PALETTE_SIZE

copy_block_with_params:
	ldy #5
copy_block_params:
	lda (COPY_PARAMS), y
	sta COPY_SRC_ADDR, y
	dey
	bpl copy_block_params

copy_block:
	ldy #0
copy_block_short:
	lda (COPY_SRC_ADDR), y
	sta (COPY_DST_ADDR), y
	iny
	cpy COPY_SIZE
	bne copy_block_short
	inc COPY_SRC_ADDR+1
	inc COPY_DST_ADDR+1
copy_skip_short:
	lda COPY_SIZE+1
	beq copy_block_end
	dec COPY_SIZE+1
	jmp copy_block_short
copy_block_end
	rts

mem_set_bytes:
	ldy #0
	ldx COPY_SIZE+1
	beq mem_set_bytes_short
mem_set_bytes_page:
	sta (COPY_DST_ADDR), y
	iny
	bne mem_set_bytes_page
	inc COPY_DST_ADDR+1
	dex
	bne mem_set_bytes_page

	ldx COPY_SIZE
	beq mem_set_bytes_end
mem_set_bytes_short:
	sta (COPY_DST_ADDR), y
	iny
	dex
	bne mem_set_bytes_short
mem_set_bytes_end:
	rts


nmi:
   jmp (NMI_VECTOR)
irq:
   jmp (IRQ_VECTOR)

   icl 'graphics.asm'
   
charset:
	ins '../../../res/charset.bin'
	icl 'palette_atari_ntsc.asm'
	icl 'palette_spectrum.asm'
	

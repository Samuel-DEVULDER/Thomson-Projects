/*
 * Copyright (c) 2007 - 2018 Magnus Lind.
 *
 * This software is provided 'as-is', without any express or implied warranty.
 * In no event will the authors be held liable for any damages arising from
 * the use of this software.
 *
 * Permission is granted to anyone to use this software, alter it and re-
 * distribute it freely for any non-commercial, non-profit purpose subject to
 * the following restrictions:
 *
 *   1. The origin of this software must not be misrepresented; you must not
 *   claim that you wrote the original software. If you use this software in a
 *   product, an acknowledgment in the product documentation would be
 *   appreciated but is not required.
 *
 *   2. Altered source versions must be plainly marked as such, and must not
 *   be misrepresented as being the original software.
 *
 *   3. This notice may not be removed or altered from any distribution.
 *
 *   4. The names of this software and/or it's copyright holders may not be
 *   used to endorse or promote products derived from this software without
 *   specific prior written permission.
 *
 */

#include "desfx.h"
#include "6502emu.h"
#include "log.h"
#include "vec.h"

struct mem_ctx
{
    u8 *mem;
    struct vec areas;
};

static void areas_merge_overlapping(struct vec *areas)
{
    int i = 1;
    int size = vec_count(areas) - 1;

    while (i < size)
    {
        u16 *end = vec_get(areas, i);
        u16 *start = vec_get(areas, i + 1);
        if (*start == *end)
        {
            /* merge */
            vec_remove(areas, i);
            vec_remove(areas, i);
            size -= 2;
        }
        else
        {
            i += 2;
        }
    }
}

static void areas_get_largest(struct vec *areas, u16 *startp, u16 *endp)
{
    struct vec_iterator i;
    u16 *pstart;
    u16 *pend;
    u16 start = 0;
    u16 end = 0;
    int size = -1;

    for (vec_get_iterator(areas, &i);
         (pstart = vec_iterator_next(&i)) != NULL;)
    {
        pend = vec_iterator_next(&i);
        if (size < *pend - *pstart)
        {
            size = *pend - *pstart;
            start = *pstart;
            end = *pend + 1;
        }
    }

    if (startp != NULL)
    {
        *startp = start;
    }

    if (endp != NULL)
    {
        *endp = end;
    }
}

static int areas_addr_cb_cmp(const void *a, const void *b)
{
    u16 ua = *(u16*)a;
    u16 ub = *(u16*)b;
    if (ua < ub)
    {
        return -1;
    }
    else if (ub < ua)
    {
        return 1;
    }
    else
    {
        return 0;
    }
}

static int areas_next_start_pos(struct vec *areas, int pos, u16 address)
{
    int result = -1;
    for (pos = pos & ~1; pos < vec_count(areas); pos += 2)
    {
        u16 *next_addr = vec_get(areas, pos);
        if (*next_addr > address + 1)
        {
            break;
        }
        if (*next_addr == address + 1)
        {
            result = pos;
            break;
        }
    }
    return result;
}

static int areas_prev_end_pos(struct vec *areas, int pos, u16 address)
{
    int result = -1;
    for (pos = (pos - 2) | 1; pos >= 0; pos -= 2)
    {
        u16 *prev_addr = vec_get(areas, pos);
        if (*prev_addr < address - 1)
        {
            break;
        }
        if (*prev_addr == address - 1)
        {
            result = pos;
            break;
        }
    }
    return result;
}

static void areas_access(struct vec *areas, u16 address)
{
    int pos;
    int orig_pos;
    int next_start_pos;
    int prev_end_pos;

    orig_pos = vec_find(areas, areas_addr_cb_cmp, &address);
    pos = orig_pos;
    if (pos < 0)
    {
        pos = -(pos + 2);
    }
    next_start_pos = areas_next_start_pos(areas, pos, address);
    prev_end_pos = areas_prev_end_pos(areas, pos, address);

    if (next_start_pos != -1)
    {
        vec_set(areas, next_start_pos, &address);
        if (prev_end_pos == -1)
        {
            u16 *addrp;
            addrp = vec_get(areas, next_start_pos - 1);
            if (addrp != NULL && *addrp >= address)
            {
                u16 addr = address - 1;
                /* shrink */
                vec_set(areas, next_start_pos - 1, &addr);
                addrp = vec_get(areas, next_start_pos - 2);
                if (*addrp == address)
                {
                    vec_remove(areas, next_start_pos - 2);
                    vec_remove(areas, next_start_pos - 2);
                }
            }
        }
    }
    if (prev_end_pos != -1)
    {
        vec_set(areas, prev_end_pos, &address);
        if (next_start_pos == -1)
        {
            u16 *addrp;
            addrp = vec_get(areas, prev_end_pos + 1);
            if (addrp != NULL && *addrp <= address)
            {
                u16 addr = address + 1;
                /* shrink */
                vec_set(areas, prev_end_pos + 1, &addr);
                addrp = vec_get(areas, prev_end_pos + 2);
                if (*addrp == address)
                {
                    vec_remove(areas, prev_end_pos + 1);
                    vec_remove(areas, prev_end_pos + 1);
                }
            }
        }
    }
    if (orig_pos < 0 && (pos & 1) == 0 &&
        next_start_pos == -1 && prev_end_pos == -1)
    {
        vec_insert(areas, pos, &address);
        vec_insert(areas, pos, &address);
    }
}

static void mem_access_write(struct mem_access *this, u16 address, u8 value)
{
    struct mem_ctx *ctx = this->ctx;

    if ((ctx->mem[1] & 4) == 4 && (ctx->mem[1] & 3) != 0 &&
        address >= 0xd000 && address < 0xe000)
    {
        /* IO-area written and visible */
        return;
    }

    ctx->mem[address] = value;
    areas_access(&ctx->areas, address);
}

static u8 mem_access_read(struct mem_access *this, u16 address)
{
    struct mem_ctx *ctx = this->ctx;
    return ctx->mem[address];
}

u16 decrunch_sfx(u8 mem[65536], u16 run, u16 *startp, u16 *endp)
{
    struct mem_ctx m;
    struct cpu_ctx r;
    r.cycles = 0;
    r.mem.ctx = &m;
    r.mem.read = mem_access_read;
    r.mem.write = mem_access_write;
    r.pc = run;
    r.sp = '\xf6';
    r.flags = 0;

    m.mem = mem;
    m.mem[1] = 0x37;
    vec_init(&m.areas, sizeof(u16));

    LOG(LOG_DEBUG, ("run %04x\n", run));

    /* setting up decrunch */
    while(r.pc >= 0x0400 || r.sp != 0xf6)
    {
        next_inst(&r);
    }

    /* decrunching */
    while(r.pc < 0x400)
    {
        next_inst(&r);
    }

    areas_merge_overlapping(&m.areas);

    areas_get_largest(&m.areas, startp, endp);
    return r.pc;
}

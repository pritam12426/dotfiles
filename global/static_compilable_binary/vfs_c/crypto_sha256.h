/*
 * Copyright (c) 2026 Pritam
 *
 * SPDX-License-Identifier: MIT
 */

/*
 * crypto_sha256.h - Portable, endian-proof, single-file, single-function sha256 implementation
 *
 * Configuration:
 *   #define CRYPTO_SHA256_STATIC   - makes crypto_sha256() static (useful for single compilation unit)
 *   (otherwise the function is declared extern)
 */

#ifndef _CRYPTO_SHA256__H_
#define _CRYPTO_SHA256__H_


#ifdef CRYPTO_SHA256_STATIC
#define CRYPTOSHA256DEF static
#else
#define CRYPTOSHA256DEF extern
#endif

#include <stddef.h> // size_t

/*
 * crypto_sha256 - computes SHA-256 hash
 * @out: output buffer (32 bytes)
 * @in:  input data
 * @len: input length in bytes
 * Returns 0 on success (may return non‑zero in future versions).
 */
CRYPTOSHA256DEF int crypto_sha256(unsigned char out[32], const unsigned char *in, size_t len);


#endif  // _CRYPTO_SHA256__H_

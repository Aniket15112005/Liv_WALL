package com.livewallpaper.app

import android.graphics.*
import android.os.Handler
import android.os.Looper
import android.service.wallpaper.WallpaperService
import android.view.SurfaceHolder
import kotlin.math.*

class LiveWallpaperService : WallpaperService() {

    override fun onCreateEngine(): Engine = WallpaperEngine()

    inner class WallpaperEngine : Engine() {

        private val handler = Handler(Looper.getMainLooper())
        private var isVisible = false
        private var frameCount = 0L
        private val targetFPS = 30L
        private val frameDelay = 1000L / targetFPS

        private val paint = Paint(Paint.ANTI_ALIAS_FLAG)
        private val path = Path()

        // Renderer state
        private val random = java.util.Random(42L)
        private var particles: List<Particle> = emptyList()
        private var stars: List<Star> = emptyList()
        private var matrixColumns: List<MatrixColumn> = emptyList()

        private val drawRunner = object : Runnable {
            override fun run() {
                draw()
                if (isVisible) {
                    handler.postDelayed(this, frameDelay)
                }
            }
        }

        override fun onCreate(surfaceHolder: SurfaceHolder) {
            super.onCreate(surfaceHolder)
            setTouchEventsEnabled(false)
        }

        override fun onSurfaceChanged(holder: SurfaceHolder, format: Int, width: Int, height: Int) {
            super.onSurfaceChanged(holder, format, width, height)
            initRenderer(width, height)
        }

        override fun onVisibilityChanged(visible: Boolean) {
            isVisible = visible
            if (visible) {
                handler.post(drawRunner)
            } else {
                handler.removeCallbacks(drawRunner)
            }
        }

        override fun onDestroy() {
            super.onDestroy()
            handler.removeCallbacks(drawRunner)
        }

        private fun initRenderer(width: Int, height: Int) {
            particles = (0 until 80).map {
                Particle(
                    x = random.nextFloat() * width,
                    y = random.nextFloat() * height,
                    vx = (random.nextFloat() - 0.5f) * 1.5f,
                    vy = (random.nextFloat() - 0.5f) * 1.5f,
                    radius = random.nextFloat() * 3f + 1f,
                    width = width.toFloat(),
                    height = height.toFloat()
                )
            }
            stars = (0 until 150).map {
                Star(
                    x = random.nextFloat() * width,
                    y = random.nextFloat() * height,
                    r = random.nextFloat() * 1.5f + 0.5f,
                    twinkleOffset = random.nextFloat() * PI.toFloat() * 2
                )
            }
            matrixColumns = (0 until (width / 14 + 1)).mapIndexed { i, _ ->
                MatrixColumn(
                    x = i * 14f,
                    speed = random.nextFloat() * 6f + 3f,
                    offset = random.nextFloat() * height,
                    height = height.toFloat()
                )
            }
        }

        private fun draw() {
            val holder = surfaceHolder
            var canvas: Canvas? = null
            try {
                canvas = holder.lockCanvas() ?: return
                val w = canvas.width.toFloat()
                val h = canvas.height.toFloat()
                frameCount++
                val t = frameCount / targetFPS.toFloat()

                val type = WallpaperSettings.wallpaperType
                val colors = WallpaperSettings.colors

                when (type) {
                    0 -> drawParticles(canvas, w, h, t, colors)
                    1 -> drawWaves(canvas, w, h, t, colors)
                    2 -> drawGeometric(canvas, w, h, t, colors)
                    3 -> drawGalaxy(canvas, w, h, t, colors)
                    4 -> drawNeonPulse(canvas, w, h, t, colors)
                    5 -> drawMatrixRain(canvas, w, h, t, colors)
                    6 -> drawAurora(canvas, w, h, t, colors)
                    7 -> drawFluidColors(canvas, w, h, t, colors)
                    else -> drawParticles(canvas, w, h, t, colors)
                }
            } finally {
                canvas?.let { holder.unlockCanvasAndPost(it) }
            }
        }

        // ─── PARTICLES ────────────────────────────────────────────
        private fun drawParticles(canvas: Canvas, w: Float, h: Float, t: Float, colors: List<Int>) {
            // Background gradient
            val bgPaint = Paint()
            bgPaint.shader = LinearGradient(
                0f, 0f, 0f, h,
                colors[0], colors[1],
                Shader.TileMode.CLAMP
            )
            canvas.drawRect(0f, 0f, w, h, bgPaint)

            // Update & draw particles
            for (p in particles) {
                p.update()
                val alpha = (180 + 75 * sin(t * 2 + p.x * 0.01f)).toInt().coerceIn(100, 255)
                // Glow
                paint.reset()
                paint.isAntiAlias = true
                paint.color = colors.last()
                paint.alpha = 60
                paint.maskFilter = BlurMaskFilter(p.radius * 3, BlurMaskFilter.Blur.NORMAL)
                canvas.drawCircle(p.x, p.y, p.radius * 2.5f, paint)
                // Core
                paint.reset()
                paint.isAntiAlias = true
                paint.color = colors.last()
                paint.alpha = alpha
                paint.maskFilter = null
                canvas.drawCircle(p.x, p.y, p.radius, paint)
            }
        }

        // ─── WAVES ────────────────────────────────────────────────
        private fun drawWaves(canvas: Canvas, w: Float, h: Float, t: Float, colors: List<Int>) {
            paint.reset()
            paint.isAntiAlias = true
            paint.shader = LinearGradient(0f, 0f, 0f, h, colors[0], colors[1], Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, w, h, paint)

            for (wave in 0 until 5) {
                val wf = wave / 5f
                val amplitude = h * (0.06f + wf * 0.04f)
                val yBase = h * (0.3f + wf * 0.14f)
                path.reset()
                path.moveTo(0f, yBase)
                var x = 0f
                while (x <= w) {
                    val y = yBase +
                        sin((x / w * 2 * PI) + t * 1.5f + wave).toFloat() * amplitude +
                        cos((x / w * PI) + t * 1f + wave * 0.5f).toFloat() * (amplitude * 0.5f)
                    path.lineTo(x, y)
                    x += 3f
                }
                path.lineTo(w, h)
                path.lineTo(0f, h)
                path.close()

                paint.reset()
                paint.isAntiAlias = true
                paint.color = colors.last()
                paint.alpha = ((0.12f + wf * 0.1f) * 255).toInt()
                paint.style = Paint.Style.FILL
                canvas.drawPath(path, paint)

                paint.style = Paint.Style.STROKE
                paint.strokeWidth = 1.5f
                paint.alpha = ((0.5f - wf * 0.3f) * 255).toInt()
                canvas.drawPath(path, paint)
            }
        }

        // ─── GEOMETRIC ────────────────────────────────────────────
        private fun drawGeometric(canvas: Canvas, w: Float, h: Float, t: Float, colors: List<Int>) {
            paint.reset()
            paint.shader = LinearGradient(0f, 0f, w, h, colors[0], colors[1], Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, w, h, paint)

            val cx = w / 2f
            val cy = h / 2f

            for (i in 0 until 6) {
                val sides = 3 + i
                val radius = 40f + i * (min(w, h) / 14f)
                val angle = t * 0.5f + i * 0.5f
                drawPolygon(canvas, cx, cy, radius, sides, angle, colors.last(), 0.08f + i * 0.03f)
            }
        }

        private fun drawPolygon(
            canvas: Canvas, cx: Float, cy: Float,
            r: Float, sides: Int, startAngle: Float,
            color: Int, alpha: Float
        ) {
            path.reset()
            for (i in 0..sides) {
                val a = startAngle + i * 2 * PI.toFloat() / sides
                val x = cx + r * cos(a)
                val y = cy + r * sin(a)
                if (i == 0) path.moveTo(x, y) else path.lineTo(x, y)
            }
            path.close()
            paint.reset()
            paint.isAntiAlias = true
            paint.color = color
            paint.alpha = (alpha * 255).toInt()
            paint.style = Paint.Style.STROKE
            paint.strokeWidth = 1.5f
            canvas.drawPath(path, paint)
        }

        // ─── GALAXY ───────────────────────────────────────────────
        private fun drawGalaxy(canvas: Canvas, w: Float, h: Float, t: Float, colors: List<Int>) {
            paint.reset()
            paint.shader = RadialGradient(w / 2, h / 2, max(w, h) * 0.7f,
                colors[1], colors[0], Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, w, h, paint)

            for (s in stars) {
                val twinkle = 0.5f + 0.5f * sin(t * 2f + s.twinkleOffset)
                paint.reset()
                paint.color = Color.WHITE
                paint.alpha = (twinkle * 200).toInt()
                canvas.drawCircle(s.x, s.y, s.r, paint)
            }

            val cx = w / 2f; val cy = h / 2f
            for (arm in 0 until 3) {
                for (i in 0 until 60) {
                    val fi = i / 60f
                    val spiral = fi * 4 * PI.toFloat() + (arm * 2 * PI.toFloat() / 3) + t * 0.5f
                    val dist = fi * min(w, h) * 0.42f
                    val x = cx + dist * cos(spiral)
                    val y = cy + dist * sin(spiral) * 0.6f
                    paint.reset()
                    paint.color = colors.last()
                    paint.alpha = (fi * 120 + 10).toInt()
                    paint.maskFilter = BlurMaskFilter(fi * 5 + 1f, BlurMaskFilter.Blur.NORMAL)
                    canvas.drawCircle(x, y, fi * 3f + 0.5f, paint)
                }
            }
        }

        // ─── NEON PULSE ───────────────────────────────────────────
        private fun drawNeonPulse(canvas: Canvas, w: Float, h: Float, t: Float, colors: List<Int>) {
            canvas.drawColor(colors[0])
            val cx = w / 2f; val cy = h / 2f
            val maxR = min(w, h) * 0.7f

            for (i in 8 downTo 0) {
                val frac = ((t + i / 8f) % 1f)
                val r = frac * maxR
                val opacity = (1f - frac)

                paint.reset()
                paint.isAntiAlias = true
                paint.color = colors[1]
                paint.alpha = (opacity * 80).toInt()
                paint.style = Paint.Style.STROKE
                paint.strokeWidth = 10f
                paint.maskFilter = BlurMaskFilter(15f, BlurMaskFilter.Blur.NORMAL)
                canvas.drawCircle(cx, cy, r, paint)

                paint.maskFilter = null
                paint.strokeWidth = 2f
                paint.alpha = (opacity * 200).toInt()
                canvas.drawCircle(cx, cy, r, paint)
            }

            // Radial lines
            val intensity = 0.5f + 0.5f * sin(t * PI.toFloat())
            for (i in 0 until 4) {
                val a = i * PI.toFloat() / 2f + t * 0.3f
                val len = min(w, h) * 0.35f
                paint.reset()
                paint.isAntiAlias = true
                paint.color = colors[2]
                paint.alpha = (intensity * 200).toInt()
                paint.strokeWidth = 2f
                paint.style = Paint.Style.STROKE
                canvas.drawLine(cx, cy, cx + len * cos(a), cy + len * sin(a), paint)
            }
        }

        // ─── MATRIX RAIN ──────────────────────────────────────────
        private fun drawMatrixRain(canvas: Canvas, w: Float, h: Float, t: Float, colors: List<Int>) {
            // Semi-transparent black overlay for trail effect
            val overlay = Paint()
            overlay.color = Color.argb(30, 0, 0, 0)
            canvas.drawRect(0f, 0f, w, h, overlay)

            val textPaint = Paint(Paint.ANTI_ALIAS_FLAG)
            textPaint.textSize = 14f
            textPaint.typeface = Typeface.MONOSPACE

            for (col in matrixColumns) {
                val head = (t * col.speed * 20 + col.offset) % (col.height + 300)
                for (row in 0 until 20) {
                    val y = head - row * 16f
                    if (y < 0 || y > col.height) continue
                    val intensity = 1f - (row / 20f)
                    val char = (0x30A0 + random.nextInt(96)).toChar()
                    textPaint.color = if (row == 0) {
                        Color.argb((intensity * 255).toInt(), 255, 255, 255)
                    } else {
                        Color.argb((intensity * 180).toInt(),
                            Color.red(colors[1]), Color.green(colors[1]), Color.blue(colors[1]))
                    }
                    canvas.drawText(char.toString(), col.x, y, textPaint)
                }
            }
        }

        // ─── AURORA ───────────────────────────────────────────────
        private fun drawAurora(canvas: Canvas, w: Float, h: Float, t: Float, colors: List<Int>) {
            paint.reset()
            paint.shader = LinearGradient(0f, 0f, 0f, h, colors[0],
                Color.rgb(10, 10, 60), Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, w, h, paint)

            // Stars
            for (s in stars) {
                val twinkle = 0.3f + 0.7f * sin(t * 1.5f + s.twinkleOffset)
                if (s.y > h * 0.65f) continue
                paint.reset()
                paint.color = Color.WHITE
                paint.alpha = (twinkle * 160).toInt()
                canvas.drawCircle(s.x, s.y, s.r, paint)
            }

            // Aurora bands
            for (band in 0 until 4) {
                val yBase = h * (0.15f + band * 0.1f)
                path.reset()
                path.moveTo(0f, yBase)
                var x = 0f
                while (x <= w) {
                    val norm = x / w
                    val y = yBase +
                        sin(norm * 3 * PI.toFloat() + t * 0.6f + band).toFloat() * (h * 0.08f) +
                        cos(norm * 2 * PI.toFloat() + t * 0.4f + band * 0.7f).toFloat() * (h * 0.04f)
                    path.lineTo(x, y)
                    x += 4f
                }
                path.lineTo(w, 0f)
                path.lineTo(0f, 0f)
                path.close()

                val bandColor = if (band % 2 == 0) colors[1] else colors[2]
                paint.reset()
                paint.isAntiAlias = true
                paint.color = bandColor
                paint.alpha = ((0.2f - band * 0.03f) * 255).toInt().coerceIn(10, 80)
                paint.maskFilter = BlurMaskFilter(30f, BlurMaskFilter.Blur.NORMAL)
                paint.style = Paint.Style.FILL
                canvas.drawPath(path, paint)
            }
        }

        // ─── FLUID COLORS ────────────────────────────────────────
        private fun drawFluidColors(canvas: Canvas, w: Float, h: Float, t: Float, colors: List<Int>) {
            paint.reset()
            paint.shader = LinearGradient(0f, 0f, w, h, colors[0], colors[1], Shader.TileMode.CLAMP)
            canvas.drawRect(0f, 0f, w, h, paint)

            for (i in 0 until 5) {
                val fi = i / 5f
                val bx = w * (0.3f + 0.4f * sin(t * 0.5f + fi * 7).toFloat())
                val by = h * (0.3f + 0.4f * cos(t * 0.4f + fi * 5).toFloat())
                val br = min(w, h) * (0.25f + 0.15f * sin(t * 0.3f + fi).toFloat())
                paint.reset()
                paint.isAntiAlias = true
                paint.color = colors[i % colors.size]
                paint.alpha = 90
                paint.maskFilter = BlurMaskFilter(br * 0.6f, BlurMaskFilter.Blur.NORMAL)
                canvas.drawCircle(bx, by, br, paint)
            }
        }
    }

    // ─── Data classes ──────────────────────────────────────────
    data class Particle(
        var x: Float,
        var y: Float,
        val vx: Float,
        val vy: Float,
        val radius: Float,
        val width: Float,
        val height: Float
    ) {
        fun update() {
            x = (x + vx + width) % width
            y = (y + vy + height) % height
        }
    }

    data class Star(val x: Float, val y: Float, val r: Float, val twinkleOffset: Float)

    data class MatrixColumn(val x: Float, val speed: Float, val offset: Float, val height: Float)
}

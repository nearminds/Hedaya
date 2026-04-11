package com.hedaya.android.ui.components

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.gestures.detectTapGestures
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.Path
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.DrawScope
import androidx.compose.ui.graphics.drawscope.Fill
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.input.pointer.pointerInput
import hedaya.shared.BranchType
import hedaya.shared.PrayerDayLog
import hedaya.shared.PrayerName
import kotlin.math.cos
import kotlin.math.sin

// Layout constants matching iOS PrayerTreeScene
private const val SCENE_W = 400f
private const val SCENE_H = 560f
private const val CX = 200f
private const val ROOT_Y = 32f
private const val TRUNK_BOTTOM_Y = 40f
private const val TRUNK_TOP_Y = 336f
private const val BRANCH_START_Y = 358f
private const val TRUNK_W_BOTTOM = 52f
private const val TRUNK_W_TOP = 28f
private const val ROOT_NODE_R = 18f
private const val BRANCH_NODE_SIZE = 36f
private const val ROOT_SPREAD = 220f
private const val BRANCH_RADIUS = 110f

private val TRUNK_FILL = Color(0xFF556B2F)
private val TRUNK_STROKE = Color(0xFF3D4F28)
private val ROOT_FILL = Color(0xFF556B2F)
private val ROOT_STROKE = Color(0xFF3D4F28)
private val BARK_COLOR = Color(0xFF383838)
private val BRANCH_LINE_COLOR = Color(0xFF333333)
private val DONE_COLOR = Color(0xFF2ECC71)

private val ROOT_PRAYERS = listOf(PrayerName.fajr, PrayerName.dhuhr, PrayerName.asr, PrayerName.maghrib, PrayerName.isha)
private val BRANCH_TYPES = listOf(
    BranchType.sunnahPrayer, BranchType.sadaqa, BranchType.morningZikr, BranchType.sleepingZikr,
    BranchType.eveningZikr, BranchType.extraDuaa, BranchType.extraZikr, BranchType.extraSalah
)

private fun rootCenter(index: Int): Offset {
    val step = ROOT_SPREAD / 4f
    val x = CX - ROOT_SPREAD / 2f + step * index
    return Offset(x, ROOT_Y)
}

private fun rootBase(index: Int): Offset {
    val progress = (index + 0.5f) / 5f
    val x = CX - TRUNK_W_BOTTOM / 2f + TRUNK_W_BOTTOM * progress * 0.85f
    return Offset(x, TRUNK_BOTTOM_Y)
}

private fun branchLeafCenter(index: Int): Offset {
    val isLeft = index < 4
    val sideIndex = if (isLeft) index else index - 4
    val angleStep = Math.PI.toFloat() / 5.5f
    val startAngle = if (isLeft) Math.PI.toFloat() * 0.72f else Math.PI.toFloat() * 0.28f
    val angle = startAngle + angleStep * sideIndex
    val x = CX + cos(angle) * BRANCH_RADIUS
    val y = BRANCH_START_Y + sin(angle) * BRANCH_RADIUS
    return Offset(x, y)
}

private fun branchStart(index: Int): Offset {
    val progress = (index + 0.5f) / 8f
    val y = TRUNK_TOP_Y - (TRUNK_TOP_Y - BRANCH_START_Y) * 0.3f - progress * 25f
    return Offset(CX, y)
}

sealed class TreeTapAction {
    data class Prayer(val prayer: PrayerName) : TreeTapAction()
    data object Quran : TreeTapAction()
    data class Branch(val branch: BranchType) : TreeTapAction()
}

@Composable
fun PrayerTreeCanvas(
    todayLog: PrayerDayLog,
    onTap: (TreeTapAction) -> Unit,
    modifier: Modifier = Modifier
) {
    Canvas(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(SCENE_W / SCENE_H)
            .pointerInput(Unit) {
                detectTapGestures { offset ->
                    val scaleX = size.width / SCENE_W
                    val scaleY = size.height / SCENE_H
                    val sx = offset.x / scaleX
                    val sy = offset.y / scaleY

                    // Check trunk tap
                    if (sx in (CX - TRUNK_W_BOTTOM / 2)..(CX + TRUNK_W_BOTTOM / 2)
                        && sy in TRUNK_BOTTOM_Y..TRUNK_TOP_Y
                    ) {
                        onTap(TreeTapAction.Quran)
                        return@detectTapGestures
                    }

                    // Check root taps
                    for (i in 0 until 5) {
                        val center = rootCenter(i)
                        val dist = kotlin.math.sqrt(
                            (sx - center.x) * (sx - center.x) + (sy - center.y) * (sy - center.y)
                        )
                        if (dist <= ROOT_NODE_R + 10f) {
                            onTap(TreeTapAction.Prayer(ROOT_PRAYERS[i]))
                            return@detectTapGestures
                        }
                    }

                    // Check branch taps
                    for (i in 0 until 8) {
                        val center = branchLeafCenter(i)
                        val dist = kotlin.math.sqrt(
                            (sx - center.x) * (sx - center.x) + (sy - center.y) * (sy - center.y)
                        )
                        if (dist <= BRANCH_NODE_SIZE / 2f + 10f) {
                            onTap(TreeTapAction.Branch(BRANCH_TYPES[i]))
                            return@detectTapGestures
                        }
                    }
                }
            }
    ) {
        val scaleX = size.width / SCENE_W
        val scaleY = size.height / SCENE_H

        fun s(offset: Offset) = Offset(offset.x * scaleX, offset.y * scaleY)
        fun sr(r: Float) = r * ((scaleX + scaleY) / 2f)

        // Draw trunk
        val trunkPath = Path().apply {
            val tl = s(Offset(CX - TRUNK_W_TOP / 2, TRUNK_TOP_Y))
            val tr = s(Offset(CX + TRUNK_W_TOP / 2, TRUNK_TOP_Y))
            val br = s(Offset(CX + TRUNK_W_BOTTOM / 2, TRUNK_BOTTOM_Y))
            val bl = s(Offset(CX - TRUNK_W_BOTTOM / 2, TRUNK_BOTTOM_Y))
            moveTo(tl.x, tl.y)
            lineTo(tr.x, tr.y)
            lineTo(br.x, br.y)
            lineTo(bl.x, bl.y)
            close()
        }
        val trunkColor = if (todayLog.quranDone) DONE_COLOR else TRUNK_FILL
        drawPath(trunkPath, trunkColor, style = Fill)
        drawPath(trunkPath, TRUNK_STROKE, style = Stroke(width = 2f * scaleX))

        // Draw roots
        val rootOffsets = intArrayOf(-1, 0, 0, 0, 1)
        for (i in 0 until 5) {
            val start = s(rootBase(i))
            val end = s(rootCenter(i))
            val mx = (start.x + end.x) / 2f + rootOffsets[i] * 18f * scaleX
            val my = (start.y + end.y) / 2f - 8f * scaleY

            val path = Path().apply {
                moveTo(start.x, start.y)
                quadraticBezierTo(mx, my, end.x, end.y)
            }
            drawPath(path, BARK_COLOR, style = Stroke(width = 5f * scaleX, cap = StrokeCap.Round))

            val isDone = todayLog.prayersCompleted.contains(ROOT_PRAYERS[i])
            val fillColor = if (isDone) DONE_COLOR else ROOT_FILL
            drawCircle(fillColor, sr(ROOT_NODE_R), end)
            drawCircle(ROOT_STROKE, sr(ROOT_NODE_R), end, style = Stroke(width = 2f * scaleX))
        }

        // Draw branches
        for (i in 0 until 8) {
            val start = s(branchStart(i))
            val end = s(branchLeafCenter(i))
            val midX = (start.x + end.x) / 2f
            val midY = (start.y + end.y) / 2f
            val sign = if (end.x < CX * scaleX) -1f else 1f
            val ctrlX = midX + sign * 25f * scaleX
            val ctrlY = midY + 15f * scaleY

            val path = Path().apply {
                moveTo(start.x, start.y)
                quadraticBezierTo(ctrlX, ctrlY, end.x, end.y)
            }
            drawPath(path, BRANCH_LINE_COLOR, style = Stroke(width = 3f * scaleX, cap = StrokeCap.Round))

            val isDone = todayLog.branchesCompleted.contains(BRANCH_TYPES[i])
            val fillColor = if (isDone) DONE_COLOR else ROOT_FILL
            val ns = sr(BRANCH_NODE_SIZE / 2f)

            when (i % 4) {
                0 -> { // Rounded rect
                    val sz = ns * 0.85f * 2f
                    drawRoundRect(fillColor, topLeft = Offset(end.x - sz / 2, end.y - sz / 2), size = Size(sz, sz), cornerRadius = androidx.compose.ui.geometry.CornerRadius(8f * scaleX))
                }
                1 -> { // Circle
                    drawCircle(fillColor, ns, end)
                    drawCircle(ROOT_STROKE, ns, end, style = Stroke(width = 1.2f * scaleX))
                }
                2 -> { // Diamond
                    val w = ns * 0.9f
                    val diamond = Path().apply {
                        moveTo(end.x, end.y - w)
                        lineTo(end.x + w, end.y)
                        lineTo(end.x, end.y + w)
                        lineTo(end.x - w, end.y)
                        close()
                    }
                    drawPath(diamond, fillColor, style = Fill)
                }
                else -> { // Ellipse
                    val ew = ns * 0.9f * 2f
                    val eh = ns * 0.7f * 2f
                    drawOval(fillColor, topLeft = Offset(end.x - ew / 2, end.y - eh / 2), size = Size(ew, eh))
                }
            }
        }
    }
}

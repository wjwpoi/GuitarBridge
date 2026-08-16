param()

Add-Type -AssemblyName System.Drawing

function New-RoundedRectanglePath {
    param(
        [System.Drawing.RectangleF]$Bounds,
        [float]$Radius
    )

    $diameter = $Radius * 2
    $path = [System.Drawing.Drawing2D.GraphicsPath]::new()
    $path.AddArc($Bounds.Left, $Bounds.Top, $diameter, $diameter, 180, 90)
    $path.AddArc($Bounds.Right - $diameter, $Bounds.Top, $diameter, $diameter, 270, 90)
    $path.AddArc($Bounds.Right - $diameter, $Bounds.Bottom - $diameter, $diameter, $diameter, 0, 90)
    $path.AddArc($Bounds.Left, $Bounds.Bottom - $diameter, $diameter, $diameter, 90, 90)
    $path.CloseFigure()
    return $path
}

function New-GuitarBridgeIcon {
    param(
        [int]$Size,
        [string]$Destination,
        [switch]$Maskable
    )

    $bitmap = [System.Drawing.Bitmap]::new($Size, $Size)
    $graphics = [System.Drawing.Graphics]::FromImage($bitmap)
    $graphics.SmoothingMode = [System.Drawing.Drawing2D.SmoothingMode]::AntiAlias
    $graphics.PixelOffsetMode = [System.Drawing.Drawing2D.PixelOffsetMode]::HighQuality

    $paper = [System.Drawing.ColorTranslator]::FromHtml('#F3F0E9')
    $surface = [System.Drawing.ColorTranslator]::FromHtml('#FFFCF7')
    $teal = [System.Drawing.ColorTranslator]::FromHtml('#245C58')
    $coral = [System.Drawing.ColorTranslator]::FromHtml('#D7614D')
    $amber = [System.Drawing.ColorTranslator]::FromHtml('#E3A34B')

    $graphics.Clear($paper)
    $outerMargin = if ($Maskable) { $Size * 0.18 } else { $Size * 0.08 }
    $outerBounds = [System.Drawing.RectangleF]::new(
        $outerMargin,
        $outerMargin,
        $Size - (2 * $outerMargin),
        $Size - (2 * $outerMargin)
    )
    $outerPath = New-RoundedRectanglePath -Bounds $outerBounds -Radius ($Size * 0.16)
    $outerBrush = [System.Drawing.SolidBrush]::new($teal)
    $graphics.FillPath($outerBrush, $outerPath)

    $gridLeft = $outerBounds.Left + ($outerBounds.Width * 0.13)
    $gridRight = $outerBounds.Right - ($outerBounds.Width * 0.13)
    $gridTop = $outerBounds.Top + ($outerBounds.Height * 0.20)
    $gridBottom = $outerBounds.Bottom - ($outerBounds.Height * 0.20)
    $gridPen = [System.Drawing.Pen]::new($surface, [Math]::Max(1.5, $Size * 0.010))
    $gridPen.Color = [System.Drawing.Color]::FromArgb(190, $surface)

    for ($string = 0; $string -lt 6; $string++) {
        $y = $gridTop + (($gridBottom - $gridTop) * $string / 5)
        $graphics.DrawLine($gridPen, $gridLeft, $y, $gridRight, $y)
    }
    for ($fret = 0; $fret -lt 5; $fret++) {
        $x = $gridLeft + (($gridRight - $gridLeft) * $fret / 4)
        $graphics.DrawLine($gridPen, $x, $gridTop, $x, $gridBottom)
    }

    $nodeSize = $Size * 0.14
    $coralBrush = [System.Drawing.SolidBrush]::new($coral)
    $amberBrush = [System.Drawing.SolidBrush]::new($amber)
    $nodeBorder = [System.Drawing.Pen]::new($surface, [Math]::Max(2, $Size * 0.018))
    $firstX = $gridLeft + (($gridRight - $gridLeft) * 0.25) - ($nodeSize / 2)
    $firstY = $gridTop + (($gridBottom - $gridTop) * 0.60) - ($nodeSize / 2)
    $secondX = $gridLeft + (($gridRight - $gridLeft) * 0.75) - ($nodeSize / 2)
    $secondY = $gridTop + (($gridBottom - $gridTop) * 0.20) - ($nodeSize / 2)
    $graphics.FillEllipse($coralBrush, $firstX, $firstY, $nodeSize, $nodeSize)
    $graphics.DrawEllipse($nodeBorder, $firstX, $firstY, $nodeSize, $nodeSize)
    $graphics.FillEllipse($amberBrush, $secondX, $secondY, $nodeSize, $nodeSize)
    $graphics.DrawEllipse($nodeBorder, $secondX, $secondY, $nodeSize, $nodeSize)

    $directory = Split-Path -Parent $Destination
    if (-not (Test-Path -LiteralPath $directory)) {
        New-Item -ItemType Directory -Path $directory | Out-Null
    }
    $bitmap.Save($Destination, [System.Drawing.Imaging.ImageFormat]::Png)

    $nodeBorder.Dispose()
    $amberBrush.Dispose()
    $coralBrush.Dispose()
    $gridPen.Dispose()
    $outerBrush.Dispose()
    $outerPath.Dispose()
    $graphics.Dispose()
    $bitmap.Dispose()
}

$webRoot = (Resolve-Path -LiteralPath (Join-Path $PSScriptRoot '..\web')).Path
New-GuitarBridgeIcon -Size 64 -Destination (Join-Path $webRoot 'guitarbridge-favicon.png')
New-GuitarBridgeIcon -Size 192 -Destination (Join-Path $webRoot 'icons\GuitarBridge-192.png')
New-GuitarBridgeIcon -Size 512 -Destination (Join-Path $webRoot 'icons\GuitarBridge-512.png')
New-GuitarBridgeIcon -Size 192 -Destination (Join-Path $webRoot 'icons\GuitarBridge-maskable-192.png') -Maskable
New-GuitarBridgeIcon -Size 512 -Destination (Join-Path $webRoot 'icons\GuitarBridge-maskable-512.png') -Maskable

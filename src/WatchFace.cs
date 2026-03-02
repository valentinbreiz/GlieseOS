using System.Drawing;
using Cosmos.Kernel.System.Graphics;
using Cosmos.Kernel.System.Graphics.Fonts;

namespace GlieseOS
{
    public class WatchFace
    {
        private readonly Canvas _canvas;
        private readonly int _cx, _cy, _radius;

        private static readonly Color ColorBlack    = Color.Black;
        private static readonly Color ColorDarkGray = Color.FromArgb(255, 26, 26, 26);
        private static readonly Color ColorBlue     = Color.FromArgb(255, 74, 158, 255);
        private static readonly Color ColorWhite    = Color.White;
        private static readonly Color ColorGray     = Color.FromArgb(255, 150, 150, 150);

        public WatchFace(Canvas canvas)
        {
            _canvas = canvas;
            var mode = canvas.Mode;
            _cx     = (int)mode.Width / 2;
            _cy     = (int)mode.Height / 2;
            _radius = (int)System.Math.Min(mode.Width, mode.Height) / 2 - 2;
        }

        public void Draw()
        {
            // Background: full black (covers display corners outside the circle)
            _canvas.Clear(ColorBlack);

            // Watch face circle: dark gray fill
            _canvas.DrawFilledCircle(ColorDarkGray, _cx, _cy, _radius);

            // Accent ring border (5 px wide, blue)
            for (int r = _radius - 4; r <= _radius; r++)
                _canvas.DrawCircle(ColorBlue, _cx, _cy, r);

            var font = PCScreenFont.DefaultFont;

            // Center: hour with seconds (default font, normal spacing)
            var now = DateTime.Now;
            string time = now.ToString("HH:mm:ss");
            int tw = time.Length * font.Width;
            _canvas.DrawString(time, font, ColorWhite, _cx - tw / 2, _cy - font.Height / 2);

            // Debug/version labels UI (inside circle, below time)
            int labelPad = 8;
            string[] debugLabels = {
                "Gliese 0.0.1",
                "Cosmos 3.0.38",
                "Dotnet 10.0.100"
            };
            int labelStartY = _cy + font.Height;
            for (int i = 0; i < debugLabels.Length; i++)
            {
                string label = debugLabels[i];
                int lw = label.Length * font.Width;
                int ly = labelStartY + i * (font.Height + labelPad);
                // Draw rectangle background (rounded not supported)
                int rectX = _cx - lw / 2 - 6;
                int rectY = ly - 2;
                int rectW = lw + 12;
                int rectH = font.Height + 4;
                _canvas.DrawFilledRectangle(ColorDarkGray, rectX, rectY, rectW, rectH);
                // Draw label text
                _canvas.DrawString(label, font, ColorBlue, _cx - lw / 2, ly);
            }

            string accent = "GlieseOS";
            int accentw = accent.Length * font.Width;
            _canvas.DrawString(accent, font, ColorGray, _cx - accentw / 2, _cy - _radius + 20);
        }
    }
}

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

            // Title: "GlieseOS"
            var font = PCScreenFont.DefaultFont;
            string title = "GlieseOS";
            int tw = title.Length * font.Width;
            _canvas.DrawString(title, font, ColorWhite, _cx - tw / 2, _cy - font.Height - 2);

            // Subtitle: "Pixel Watch 3"
            string sub = "Pixel Watch 3";
            int sw = sub.Length * font.Width;
            _canvas.DrawString(sub, font, ColorGray, _cx - sw / 2, _cy + 4);
        }
    }
}

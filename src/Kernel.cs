using Cosmos.Kernel.System.Graphics;
using Sys = Cosmos.Kernel.System;

namespace GlieseOS
{
    public class Kernel : Sys.Kernel
    {
        private WatchFace _watchFace;

        protected override void BeforeRun()
        {
            Canvas canvas = KernelConsole.Canvas;
            _watchFace = new WatchFace(canvas);
            _watchFace.Draw();
            canvas.Display();
        }

        protected override void Run()
        {
            // Static POC: BeforeRun drew once, halt the main loop.
            // Future: redraw on timer tick for animated clock hands.
            Stop();
        }
    }
}

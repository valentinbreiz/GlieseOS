using Cosmos.Kernel.System.Graphics;
using Sys = Cosmos.Kernel.System;

namespace GlieseOS
{
    public class Kernel : Sys.Kernel
    {
        private WatchFace _watchFace;
        private Canvas _canvas;

        protected override void BeforeRun()
        {
            _canvas = KernelConsole.Canvas;
            _watchFace = new WatchFace(_canvas);
        }

        protected override void Run()
        {
            _watchFace.Draw();
            _canvas.Display();
        }
    }
}

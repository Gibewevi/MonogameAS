using Microsoft.Xna.Framework;
using Microsoft.Xna.Framework.Graphics;

namespace MonogameAS.Extensions;

public static class SpriteBatchExtensions
{
    public static void DrawPixel(this SpriteBatch sb, Texture2D pixel, Rectangle rect, Color color) =>
        sb.Draw(pixel, rect, color);
}

﻿using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.Collections.Specialized;
using System.ComponentModel;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.IO;
using System.Drawing.Imaging;
using SkiaSharp;
using System.Globalization;

namespace STORMWORKS_Simulator
{
    public class StormworksMonitor
    { // redundant can be removed
        public event EventHandler OnMonitorSizeChanged;
        public Point Size
        {
            get
            {
                return _Size;
            }
            set
            {
                _Size = value;
                OnMonitorSizeChanged?.Invoke(this, new EventArgs());
            }
        }

        private Point _Size;

        public StormworksMonitor()
        {
            Size = new Point(32, 32);
        }
    }

    public class ScreenVM : INotifyPropertyChanged
    {
        public readonly double CanvasScale = 5.0f;
        public static List<string> ScreenDescriptionsList { get; private set; } = new List<string>() { "1x1", "2x1", "2x2", "3x2", "3x3", "5x3", "9x5" };

        public event PropertyChangedEventHandler PropertyChanged;
        public event EventHandler<ScreenVM> OnResolutionChanged;
        public event EventHandler<ScreenVM> OnTouchChanged;
        public event EventHandler<ScreenVM> OnPowerChanged;

        #region ScreenInfo
        public string ScreenResolutionDescription
        {
            // using Strings for screen resolution as we also need to handle this from a text based pipe, and it's an extremely
            // tight-scoped application, so no reason to over-do things.
            get
            {
                return $"{Monitor.Size.X}x{Monitor.Size.Y}";
            }

            set
            {
                var splits = value.Split('x');
                var width = int.Parse(splits[0], CultureInfo.InvariantCulture) * 32;
                var height = int.Parse(splits[1], CultureInfo.InvariantCulture) * 32;

                ScreenResolutionDescriptionIndex = ScreenDescriptionsList.IndexOf(value);

                Monitor.Size = new Point(width, height);

                FrontBuffer = new WriteableBitmap((int)Monitor.Size.X, (int)Monitor.Size.Y, 96, 96, PixelFormats.Bgra32, null);
                _BackBuffer = new WriteableBitmap((int)Monitor.Size.X, (int)Monitor.Size.Y, 96, 96, PixelFormats.Bgra32, null);

                MapBuffer = new WriteableBitmap((int)Monitor.Size.X, (int)Monitor.Size.Y, 96, 96, PixelFormats.Bgra32, null);
                _BackMapBuffer = new WriteableBitmap((int)Monitor.Size.X, (int)Monitor.Size.Y, 96, 96, PixelFormats.Bgra32, null);

                PrepareBufferForDrawing(_BackBuffer, ref DrawingCanvas);
                PrepareBufferForDrawing(_BackMapBuffer, ref MapCanvas);

                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(null));

                if (IsPowered)
                {
                    OnResolutionChanged?.Invoke(this, this);
                }
            }
        }
        public int ScreenResolutionDescriptionIndex { get; set; }

        public StormworksMonitor Monitor { get; private set; }

        public double CanvasRotation
        {
            get => IsPortrait ? 90 : 0;
        }

        public bool IsPortrait
        {
            get { return _IsPortrait; }
            set
            {
                _IsPortrait = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(null));
            }
        }

        public bool IsPowered
        {
            get { return _IsPowered; }
            set
            {
                _IsPowered = value;
                PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(null));
                OnPowerChanged?.Invoke(this, this);
            }
        }

        private bool _IsPortrait = false;
        private bool _IsPowered = true;
        #endregion



        #region Drawing
        public Point CanvasSize { get => new Point(Monitor.Size.X * CanvasScale, Monitor.Size.Y * CanvasScale); }
        public SKSurface DrawingCanvas;
        public WriteableBitmap FrontBuffer { get; private set; }
        private WriteableBitmap _BackBuffer;
        #endregion

        #region MapDrawing
        public SKSurface MapCanvas;
        public WriteableBitmap MapBuffer { get; private set; }
        private WriteableBitmap _BackMapBuffer;
        #endregion

        public int ScreenNumber { get; private set; }

        #region Touches
        // touch data
        public string LastTouchCommand = "";
        public Point TouchPosition = new Point(0, 0);
        public bool IsLDown { get => _IsLDown && _IsInCanvas; }
        public bool IsRDown { get => _IsRDown && _IsInCanvas; }

        public Canvas _Canvas { private get; set; }
        private bool _IsLDown = false;
        private bool _IsRDown = false;
        private bool _IsInCanvas = false;
        #endregion


        public ScreenVM(int screenNumber)
        {
            ScreenNumber = screenNumber;
            Monitor = new StormworksMonitor();
            ScreenResolutionDescription = ScreenDescriptionsList[0];
        }

        public void SwapFrameBuffers()
        {
            // swap front buffers
            _BackBuffer.AddDirtyRect(new Int32Rect(0, 0, (int)_BackBuffer.Width, (int)_BackBuffer.Height));
            _BackBuffer.Unlock();

            var temp = FrontBuffer;
            FrontBuffer = _BackBuffer;
            _BackBuffer = temp;

            PrepareBufferForDrawing(_BackBuffer, ref DrawingCanvas);


            // swap map buffers
            _BackMapBuffer.AddDirtyRect(new Int32Rect(0, 0, (int)_BackMapBuffer.Width, (int)_BackMapBuffer.Height));
            _BackMapBuffer.Unlock();

            temp = MapBuffer;
            MapBuffer = _BackMapBuffer;
            _BackMapBuffer = temp;

            PrepareBufferForDrawing(_BackMapBuffer, ref MapCanvas);


            PropertyChanged?.Invoke(this, new PropertyChangedEventArgs(null));
        }

        public void PrepareBufferForDrawing(WriteableBitmap buffer, ref SKSurface canvas)
        {
            if (canvas != null)
            {
                canvas.Dispose();
            }

            var skImageInfo = new SKImageInfo()
            {
                Width = (int)buffer.Width,
                Height = (int)buffer.Height,
                ColorType = SKColorType.Bgra8888,
                AlphaType = SKAlphaType.Premul,
                ColorSpace = SKColorSpace.CreateSrgb()
            };
            buffer.Lock();
            canvas = SKSurface.Create(skImageInfo, buffer.BackBuffer);
        }

        public void Clear()
        {
            _BackBuffer.Clear();
        }

        // mouse event handling
        public void OnMouseEnter(Canvas canvas, MouseEventArgs e)
        {
            _IsInCanvas = true;
            UpdateTouchPosition(canvas, e);
        }

        public void OnMouseLeave(Canvas canvas, MouseEventArgs e)
        {
            _IsInCanvas = false;
            UpdateTouchPosition(canvas, e);
        }

        public void OnMouseMove(Canvas canvas, MouseEventArgs e)
        {
            _IsLDown = e.LeftButton == MouseButtonState.Pressed;
            _IsRDown = e.RightButton == MouseButtonState.Pressed;
            UpdateTouchPosition(canvas, e);
        }

        public void OnRightButtonDown(Canvas canvas, MouseButtonEventArgs e)
        {
            _IsRDown = true;
            UpdateTouchPosition(canvas, e);
        }

        public void OnLeftButtonDown(Canvas canvas, MouseButtonEventArgs e)
        {
            _IsLDown = true;
            UpdateTouchPosition(canvas, e);
        }

        public void OnLeftButtonUp(Canvas canvas, MouseButtonEventArgs e)
        {
            _IsLDown = false;
            UpdateTouchPosition(canvas, e);
        }

        public void OnRightButtonUp(Canvas canvas, MouseButtonEventArgs e)
        {
            _IsRDown = false;
            UpdateTouchPosition(canvas, e);
        }

        private void UpdateTouchPosition(Canvas canvas, MouseEventArgs e)
        {
            // Stormworks only updates positions when buttons are being pressed
            // There is no on-hover
            if (IsRDown || IsLDown)
            {
                TouchPosition = e.GetPosition(canvas);
                TouchPosition.X = Math.Floor(TouchPosition.X / CanvasScale);
                TouchPosition.Y = Math.Floor(TouchPosition.Y / CanvasScale);
            }

            if (IsPowered)
            {
                OnTouchChanged?.Invoke(this, this);
            }
        }
    }
}

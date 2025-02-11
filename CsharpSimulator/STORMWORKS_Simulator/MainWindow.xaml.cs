﻿using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;
using System.Windows.Media.Imaging;
using System.Windows.Navigation;
using System.Windows.Shapes;
using System.Windows.Threading;
using System.Threading;
using System.Collections;
using System.IO.Pipes;
using System.IO;
using System.ComponentModel.Composition;
using System.ComponentModel.Composition.Hosting;
using System.Net.Sockets;
using System.Net;

namespace STORMWORKS_Simulator
{
    public partial class MainWindow : Window
    {
        public StormworksMonitor Monitor;
        public MainVM ViewModel;
        public SocketConnection VSConnection;
        public Timer KeepAliveTimer;
        public TickHandler TickHandler;

        public MainWindow(CommandLineArgs args)
        {
            Logger.SetLog(args.LogFilepath);
            Logger.ErrorEnabled = args.EnableLogging;
            Logger.InfoEnabled = args.EnableLogging;

            Logger.Log("Launching, time stamp.");
            ViewModel = new MainVM();
            DataContext = ViewModel;

            InitializeComponent();

            TickHandler = new TickHandler(ViewModel);
            VSConnection = new SocketConnection(ViewModel);
            VSConnection.OnPipeClosed += Pipe_OnPipeClosed;
            VSConnection.OnLineRead += TickHandler.OnLineRead;


            ViewModel.OnScreenResolutionChanged += (s, vm) =>
            {
                if(Properties.Settings.Default.ResetZoomAutomatically)
                {
                    CanvasZoom.Reset();
                }
            };
            ViewModel.OnScreenResolutionChanged += (s, vm) => VSConnection.SendMessage("SCREENSIZE", $"{vm.ScreenNumber + 1}|{vm.Monitor.Size.X}|{vm.Monitor.Size.Y}");
            ViewModel.OnScreenTouchChanged += SendTouchDataIfChanged;
            ViewModel.OnPowerChanged += (s, vm) => VSConnection.SendMessage("SCREENPOWER", $"{vm.ScreenNumber + 1}|{ (vm.IsPowered ? "1" : "0") }");
            ViewModel.OnTickrateChanged += (s, vm) => VSConnection.SendMessage("TICKRATE", $"{vm.TickRate}|{vm.FrameSkip}");

            CanvasZoom.OnPanChanged += (s, transform) => {
                Properties.Settings.Default.LastPanX = transform.X;
                Properties.Settings.Default.LastPanY = transform.Y;
            };
            CanvasZoom.OnZoomChanged += (s, transform) => {
                Properties.Settings.Default.LastZoomX = transform.ScaleX;
                Properties.Settings.Default.LastZoomY = transform.ScaleY;
            };

            

            KeepAliveTimer = new Timer(OnKeepAliveTimer, null, 100, 100);
            
            var screen = ViewModel.GetOrAddScreen(1);

            if (!Properties.Settings.Default.ResetZoomAutomatically)
            {
                CanvasZoom.SetPanAndZoom(
                    Properties.Settings.Default.LastPanX,
                    Properties.Settings.Default.LastPanY,
                    Properties.Settings.Default.LastZoomX,
                    Properties.Settings.Default.LastZoomY);
            }

            Closing += (s,e) => {
                Properties.Settings.Default.Save();
            };

            // set HW acceleration from previous value
            if (ViewModel.EnableHWAccel)
            {
                RenderOptions.ProcessRenderMode = System.Windows.Interop.RenderMode.Default;
            }
            else
            {
                RenderOptions.ProcessRenderMode = System.Windows.Interop.RenderMode.SoftwareOnly;
            }

            Logger.Log("MainWindow Initialized and running");
        }

        private void OnKeepAliveTimer(object state)
        {   // sends simple Alive message once every 100 millis, to ensure the connection is still alive
            // allows the UI to close sooner than it might otherwise, once the debugger ends
            try
            {
                VSConnection.SendMessage("ALIVE");
            }
            catch (Exception e)
            {   // squash the error or it will confuse users in VSCode wondering why there's a bright red error
                Logger.Error($"OnKeepAliveTimer - Exception - Closing Application - {e}");
                Application.Current.Dispatcher.Invoke(() =>
                {
                    Application.Current.Shutdown();
                });
            }

            //TickHandler.OnLineRead(this, $"COLOUR|255|255|255|255");
            //FakeDraw(2, 2, 6, 6, "+");
            //FakeDraw(12, 2, 7, 7, "+");
            //FakeDraw(22, 2, 8, 8, "+");
            //
            //TickHandler.OnLineRead(this, $"COLOUR|255|0|0|255");
            //FakeDraw(2, 12, 6, 6, "+", -1);
            //FakeDraw(12, 12, 7, 7, "+", -1);
            //FakeDraw(22, 12, 8, 8, "+", -1);
            //
            //TickHandler.OnLineRead(this, $"COLOUR|0|0|255|255");
            //FakeDraw(2, 22, 6, 6, "++");
            //FakeDraw(12, 22, 7, 7, "++");
            //FakeDraw(22, 22, 8, 8, "++");
            //FakeDraw(32, 22, 9, 9, "++");
            //FakeDraw(42, 22, 10, 10, "++");
            //
            //TickHandler.OnLineRead(this, $"COLOUR|0|0|255|255");
            //FakeDraw(2, 42, 6, 6, " ++");
            //FakeDraw(12, 42, 7, 7, " ++");
            //FakeDraw(22, 42, 8, 8, " ++");
            //FakeDraw(32, 42, 9, 9, " ++");
            //FakeDraw(42, 42, 10, 10, " ++");
            //
            //TickHandler.OnLineRead(this, $"COLOUR|0|255|0|255");
            //FakeDraw(10, 55, 40, 10, "TOGGLE");
            //FakeDraw(64, 10, 30, 10, "DAN DAN DAN DAN DAN");
            //
            //TickHandler.OnLineRead(this, "TICKEND|1");
        }

        //private void FakeDraw(int x, int y, int width, int height, string text, int align = 0)
        //{
        //    TickHandler.OnLineRead(this, $"RECT|1|0|{x}|{y}|{width}|{height}");
        //    TickHandler.OnLineRead(this, $"TEXTBOX|1|{x}|{y}|{width}|{height}|{align}|{align}|{text}");
        //}

        private void Pipe_OnPipeClosed(object sender, EventArgs e)
        {
            Logger.Error($"Pipe_OnPipeClosed - Closing Application");

            Application.Current.Dispatcher.Invoke(() =>
            {
                Application.Current.Shutdown();
            });
        }

        private void OnResetClicked(object sender, RoutedEventArgs e)
        {
            CanvasZoom.Reset();
        }

        private void SendTouchDataIfChanged(object sender, ScreenVM vm)
        {
            // only send the update if things actually changed
            var xTouchPos = Math.Min(Math.Max(vm.TouchPosition.X, 0), vm.Monitor.Size.X-1);
            var yTouchPos = Math.Min(Math.Max(vm.TouchPosition.Y, 0), vm.Monitor.Size.Y-1);

            var xAltTouchPos = Math.Min(Math.Max(vm.TouchAltPosition.X, 0), vm.Monitor.Size.X - 1);
            var yAltTouchPos = Math.Min(Math.Max(vm.TouchAltPosition.Y, 0), vm.Monitor.Size.Y - 1);

            var newCommand = $"{vm.ScreenNumber + 1}|{(vm.IsLDown || vm.IsRDown ? '1' : '0') }|{ (vm.IsLDown && vm.IsRDown ? '1' : '0') }|{xTouchPos}|{yTouchPos}|{xAltTouchPos}|{yAltTouchPos}";
            if (newCommand != vm.LastTouchCommand)
            {
                vm.LastTouchCommand = newCommand;
                VSConnection.SendMessage("TOUCH", newCommand);
            }
        }

        private void OnAddScreenClicked(object sender, RoutedEventArgs e)
        {
            ViewModel.GetOrAddScreen(ViewModel.ScreenVMs.Count + 1);
        }

        // dirty event handling, but easier than going through all the bindings for this; as they're not designed to work with commands by default
        // redirect the event manually, to the correct screenVM
        private void Canvas_MouseRightButtonUp(object sender, MouseButtonEventArgs e) { ((sender as Canvas).DataContext as ScreenVM).OnRightButtonUp(sender as Canvas, e);}

        private void Canvas_MouseLeftButtonUp(object sender, MouseButtonEventArgs e) { ((sender as Canvas).DataContext as ScreenVM).OnLeftButtonUp(sender as Canvas, e); }

        private void Canvas_MouseRightButtonDown(object sender, MouseButtonEventArgs e) { ((sender as Canvas).DataContext as ScreenVM).OnRightButtonDown(sender as Canvas, e); }

        private void Canvas_MouseLeftButtonDown(object sender, MouseButtonEventArgs e) { ((sender as Canvas).DataContext as ScreenVM).OnLeftButtonDown(sender as Canvas, e); }

        private void Canvas_MouseLeave(object sender, MouseEventArgs e) { ((sender as Canvas).DataContext as ScreenVM).OnMouseLeave(sender as Canvas, e); }

        private void Canvas_MouseEnter(object sender, MouseEventArgs e) { ((sender as Canvas).DataContext as ScreenVM).OnMouseEnter(sender as Canvas, e); }

        private void Canvas_MouseMove(object sender, MouseEventArgs e) { ((sender as Canvas).DataContext as ScreenVM).OnMouseMove(sender as Canvas, e); }
    }
}

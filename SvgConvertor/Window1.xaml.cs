﻿/*
 * Created by Visual Studio 2010
 * User: je7sen Then
 * Date: 05/06/2013
 * Time: 16:24
 * 
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.IO.Ports;
using System.Linq;
using System.Text;
using System.Timers;
using System.Threading;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;

using Svg2Xaml;

namespace SvgConvertor
{
	/// <summary>
	/// Interaction logic for Window1.xaml
	/// </summary>
	public partial class Window1 : Window
	{
        #region localvariable
        /// <summary>
        /// Svg full file name with path use to send to plotter.
        /// </summary>
        private string fileName;
        /// <summary>
        /// The directory where svg file stored inside.
        /// </summary>
        private string directory;
        /// <summary>
        /// <"SerialPort">
        /// </summary>
        public string comport;
        static SerialPort SPort;
        static Boolean portstat = false;
        #endregion
		

        #region Initialisation
        public Window1()
        {
            InitializeComponent();
            /// get COM PORT
            try
            {
                string[] ports = SerialPort.GetPortNames();
                foreach (string port in ports)
                    Combobox1.Items.Add(new TextBlock { Text = port });
            }

            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
                throw ex;
            }

        }
        #endregion
        
        #region Events
        void button1_Click(object sender, RoutedEventArgs e)
		{
			TextBlock1.Text = "Opening file...";
            		
			try
			{
				Microsoft.Win32.OpenFileDialog dialog = new Microsoft.Win32.OpenFileDialog();
	            dialog.DefaultExt = ".svg";
	            dialog.Filter = "Svg (.svg)|*.svg";
	            if (dialog.ShowDialog() == true)
	            {
	                fileName = dialog.FileName;
                    fileName = fileName.Replace("\\","\\\\");
                    System.Diagnostics.Debug.WriteLine("Fullpath: " + fileName);
                    
                    //directory = getDirectory(fileName);
                    //System.Diagnostics.Debug.WriteLine("Directory: "+directory);
	                TextBlock1.Text = fileName + " loaded.";
	                
	                using(FileStream stream = new FileStream(fileName, FileMode.Open, FileAccess.Read))
	                	ImageControl.Source = SvgReader.Load(stream);

                    // write the svg path into pde
	            }
			}
			catch(Exception ex)
			{
				MessageBox.Show(ex.Message);
				throw ex;
			}
		}
        void button2_Click(object sender, RoutedEventArgs e)
        {
            TextBlock1.Text = "No COM is selected";
            if (Combobox1.SelectedIndex > -1)
            {
                comport = Combobox1.Text;
                TextBlock1.Text = "COM set to " + comport;
                ReWritePDE();
            }
       
        }
        void button3_Click(object sender, RoutedEventArgs e)
        {
            TextBlock1.Text = "No file is selected";
            if (fileName != null)
            {
                SendToPlot();
            }
        }
        void button4_Click(object sender, RoutedEventArgs e)
        {
            TextBlock1.Text = "No COM is selected";
                if (comport !=null && portstat == false)
                {
                    //create serial port configuration
                    SPort = new SerialPort(comport, 9600, Parity.None, 8, StopBits.One);
                    SPort.ReadTimeout = 500;
                    SPort.WriteTimeout = 500;
                    SPort.Open();
                    portstat = true;
                    
                    //delay 200ms and send start signal to serial port
                    Thread.Sleep(200);
                    SPort.WriteLine("S");
                    SPort.WriteLine("\n");
                    Thread.Sleep(200);

                    TextBlock1.Text = "Connected.";

                }
           
        }
        void button5_Click(object sender, RoutedEventArgs e)
        {
            TextBlock1.Text = "No COM is selected";
                if (portstat)
                {
                    //delay 200ms then send End signal to serial port
                    Thread.Sleep(200);
                    SPort.WriteLine("T");
                    SPort.WriteLine("\n");

                    //close serial port
                    SPort.Close();
                    portstat = false;

                    TextBlock1.Text = "Disconnected.";
                }
            
        }
        void button6_Click(object sender, RoutedEventArgs e)
        {
            TextBlock1.Text = "No COM is selected";
            if (portstat == true)
            {
                TextBlock1.Text = "Moving X_axis Up.";
                //send up signal to serial port
                Thread.Sleep(200);
                SPort.WriteLine("U");
                SPort.WriteLine("\n");
            }
            
        }
        void button7_Click(object sender, RoutedEventArgs e)
        {
            TextBlock1.Text = "No COM is selected";
            if (portstat == true)
            {
                TextBlock1.Text = "Moving X_axis Down.";
                //send Down signal to serial port
                Thread.Sleep(200);
                SPort.WriteLine("X");
                SPort.WriteLine("\n");
            }
        }
        void button8_Click(object sender, RoutedEventArgs e)
        {
            TextBlock1.Text = "No COM is selected";
            if (portstat == true)
            {
                TextBlock1.Text = "Moving Y_axis Left.";
                //send left signal to serial port
                Thread.Sleep(200);
                SPort.WriteLine("L");
                SPort.WriteLine("\n");
            }
        }
        void button9_Click(object sender, RoutedEventArgs e)
        {
            TextBlock1.Text = "No COM is selected";
            if (portstat == true)
            {
                TextBlock1.Text = "Moving Y_axis Right.";
                //send Right signal to serial port
                Thread.Sleep(200);
                SPort.WriteLine("R");
                SPort.WriteLine("\n");
            }
        }
        void button10_Click(object sender, RoutedEventArgs e)
        {
            TextBlock1.Text = "No COM is selected";
            if (portstat == true)
            {
                TextBlock1.Text = "Set X_axis & Y_axis to 0.";
                //send set signal to serial port
                Thread.Sleep(200);
                SPort.WriteLine("E");
                SPort.WriteLine("\n");
            }
        }
        private void Image_ImageFailed(object sender, ExceptionRoutedEventArgs e)
        {

        }
        #endregion
       

        #region Methods
        /// <summary>
        /// Write svg source to pde script then call processing-java.
        /// </summary>
        private void SendToPlot()
        {
            try
            {
                // TODO: make it can be configurable
                TextBlock1.Text = "Start drawing...";
                string f = @"E:\MyProjects\SVG_Convertor\SVGReader\SVGReader.pde";

                // 1. Programmically compose pde script with all variable value in the script then write to a place.
                StreamReader reader = new StreamReader(f);
                string line = string.Empty;
                string output = string.Empty;
                int lineNo = 0;
                while ((line = reader.ReadLine()) != null)
                {
                    lineNo++;
                    if (lineNo == 33)
                        output += "final String filePath = \"" + fileName + "\";" + "\n";
                    else
                        output += line + "\n";
                }
                reader.Close();

                StreamWriter writer = new StreamWriter(f, false);
                writer.Write(output);
                writer.Flush();
                writer.Close();

                // 2. Execute command.                
                //string p = @"--sketch="+directory+" --output="+directory+"\build --force --run";
                // TODO: Stored at app.config
                string app = @"E:\processing-2.0b8\processing-java";
                string p = @"--sketch=test --output=build --force --run";
                Process.Start(app, p);
            }
            catch (Exception ex)
            {
                MessageBox.Show(ex.Message);
                throw ex;
                //return; //you application may continue even error happen
            }
        }
        /// <summary>
        /// TODO: Extract directory from a full file path.
        /// </summary>
        /// <param name="fullPath"></param>
        /// <returns></returns>
        private string getDirectory(string fullPath)
        {
            string output = string.Empty;
            int index = fullPath.IndexOf("\\");
            //string[] pieces = fullPath.Split(new 
            if (index > -1) output = fullPath.Substring(0, index);

            return output;
        }
        private void ReWritePDE()
        {
            try
            {
                string f = @"E:\MyProjects\SVG_Convertor\SVGReader\SVGReader.pde";

                // 1. Programmically compose pde script with all variable value in the script then write to a place.
                StreamReader reader = new StreamReader(f);
                string line = string.Empty;
                string output = string.Empty;
                int lineNo = 0;
                while ((line = reader.ReadLine()) != null)
                {
                    lineNo++;
                    if (lineNo == 32)
                        output += "final String serialPort = \"" + comport + "\";" + "\n";
                    else
                        output += line + "\n";
                }
                reader.Close();

                StreamWriter writer = new StreamWriter(f, false);
                writer.Write(output);
                writer.Flush();
                writer.Close();
            }
            catch (Exception)
            {

                throw;
            }


        }
        #endregion
    }
}
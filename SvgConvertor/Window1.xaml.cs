/*
 * Created by SharpDevelop.
 * User: yeang-shing.then
 * Date: 05/06/2013
 * Time: 16:24
 * 
 * To change this template use Tools | Options | Coding | Edit Standard Headers.
 */
using System;
using System.Collections.Generic;
using System.Diagnostics;
using System.IO;
using System.Text;
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
		/// <summary>
		/// Svg full file name with path use to send to plotter.
		/// </summary>
		private string fileName;
		
		public Window1()
		{
			InitializeComponent();
		}
		
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
	                // TODO: Load into drawing area?
	                fileName = dialog.FileName;
	                TextBlock1.Text = fileName + " loaded.";
	                
	                using(FileStream stream = new FileStream(fileName, FileMode.Open, FileAccess.Read))
	                	ImageControl.Source = SvgReader.Load(stream);
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
			TextBlock1.Text = "Start drawing...";
			
			// TODO: Execute dos command?
			//Process.Start();
		}
	}
}
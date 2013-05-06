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
using System.Text;
using System.Windows;
using System.Windows.Controls;
using System.Windows.Data;
using System.Windows.Documents;
using System.Windows.Input;
using System.Windows.Media;

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
			System.Diagnostics.Debug.WriteLine("Opening file...");
			Microsoft.Win32.OpenFileDialog dialog = new Microsoft.Win32.OpenFileDialog();
            dialog.DefaultExt = ".svg";
            dialog.Filter = "Svg (.svg)|*.svg";
            if (dialog.ShowDialog() == true)
            {
                // TODO: Load into drawing area?
                fileName = dialog.FileName;
                System.Diagnostics.Debug.WriteLine(fileName);
            }
		}
		
		void button2_Click(object sender, RoutedEventArgs e)
		{
			System.Diagnostics.Debug.WriteLine("Start ...");
			// TODO: Execute dos command?
			//Process.Start();
		}
	}
}
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
		public Window1()
		{
			InitializeComponent();
		}
		
		void button1_Click(object sender, RoutedEventArgs e)
		{
			System.Diagnostics.Debug.WriteLine("Opening file...");
		}
		
		void button2_Click(object sender, RoutedEventArgs e)
		{
			System.Diagnostics.Debug.WriteLine("Start ...");
			// TODO: Execute dos command?
			//Process.Start();
		}
	}
}
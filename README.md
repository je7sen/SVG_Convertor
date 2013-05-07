SVG_Convertor
=============
A GUI to load the SVG file (Inkscape file) and convert those path into point and send to xy plotter.

-------------
Requirement
-------------
- [Processing IDE 2.0.8](http://processing.googlecode.com/files/processing-2.0b8-windows32.zip)
- Visual Studio 2010 or above
- [Svg2Xaml](http://svg2xaml.codeplex.com/) - Library for convert svg to xaml in WPF Windows form.


Setup Configuration
-------------------
1. Install Processing IDE 1.5.1 from the link above and paste the folowing file from lib folder (this configuration no longer needed for Processing IDE 2.0b8)

		copy RXTXcomm  to 'directory'\processing-1.5.1\java\lib\ext
		copy both rxtxParallel.dll and rxtxSerial.dll to  'directory'\processing-1.5.1\java\bin
		
Q&A
------
1. If fail to compile, please configure compile output as your compatible mode. Project properties | Compiling | Target CPU.


References
------------
- [ProcessingIDE](http://processing.org/)
- [Configure Serial Input for ProcessingIDE 1.5.1](http://forum.processing.org/topic/how-do-i-install-rxtx-2-2pre1-jar-on-windows-7#25080000000981023)
- [FamFamFam Icon Collection](http://www.famfamfam.com/)
- [Xamalot](http://www.xamalot.com/) - Free vector graphics.
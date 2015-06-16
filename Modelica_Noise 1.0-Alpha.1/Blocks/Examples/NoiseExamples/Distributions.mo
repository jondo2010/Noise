within Modelica_Noise.Blocks.Examples.NoiseExamples;
model Distributions "Demonstrates noise with different types of distributions"
  extends Modelica.Icons.Example;
  parameter Modelica.SIunits.Time samplePeriod=0.02
    "Sample period of all blocks";
  inner Blocks.Noise.GlobalSeed globalSeed(useAutomaticSeed=false)
               annotation (Placement(transformation(extent={{40,60},{60,80}})));

  Integer n=if time < 0.5 then 12 else 2;

  Noise.GenericNoise uniformNoise(
    useAutomaticLocalSeed=false,
    fixedLocalSeed=1,
    samplePeriod=samplePeriod,
    redeclare function distribution =
        Modelica_Noise.Math.Distributions.Uniform.quantile (y_min=-1, y_max=3))
    annotation (Placement(transformation(extent={{-60,70},{-40,90}})));
  Noise.GenericNoise normalNoise(
    useAutomaticLocalSeed=false,
    fixedLocalSeed=1,
    samplePeriod=samplePeriod,
    redeclare function distribution =
        Modelica_Noise.Math.Distributions.Normal.quantile (mu=0, sigma=1))
    annotation (Placement(transformation(extent={{-60,30},{-40,50}})));
  Noise.GenericNoise weibullNoise(
    useAutomaticLocalSeed=false,
    fixedLocalSeed=1,
    samplePeriod=samplePeriod,
    redeclare function distribution =
        Modelica_Noise.Math.Distributions.Weibull.quantile (
        lamba=1,
        lambda=1,
        k=1))
    annotation (Placement(transformation(extent={{-60,-10},{-40,10}})));
 annotation (experiment(StopTime=2), Diagram(coordinateSystem(
          preserveAspectRatio=false, extent={{-100,-100},{100,100}}), graphics),
    Documentation(info="<html>
<p>
This example demonstrates different noise distributions methods that can be selected
for a Noise block. All the blocks use samplePeriod = 0.02 s, y_min=-1, y_max=3, and have
identical fixedLocalSeed. This means that the same random numbers are drawn for the blocks.
However, the random numbers are differently transformed according to the selected
truncated distributions, and therefore the blocks have different output values.
Simulation results are shown in the next diagram:
</p>

<p><blockquote>
<img src=\"modelica://Modelica_Noise/Resources/Images/Blocks/Examples/NoiseExamples/Distributions.png\">
</blockquote></p>
</html>", revisions="<html>
<p>
<table border=1 cellspacing=0 cellpadding=2>
<tr><th>Date</th> <th align=\"left\">Description</th></tr>

<tr><td valign=\"top\"> Feb. 18, 2015 </td>
    <td valign=\"top\"> 

<table border=0>
<tr><td valign=\"top\">
         <img src=\"modelica://Modelica_Noise/Resources/Images/Blocks/Noise/dlr_logo.png\">
</td><td valign=\"bottom\"> 
         Initial version implemented by
         A. Kl&ouml;ckner, F. v.d. Linden, D. Zimmer, M. Otter.<br>
         <a href=\"http://www.dlr.de/rmc/sr/en\">DLR Institute of System Dynamics and Control</a>
</td></tr></table>
</td></tr>

</table>
</p>
</html>"));
end Distributions;

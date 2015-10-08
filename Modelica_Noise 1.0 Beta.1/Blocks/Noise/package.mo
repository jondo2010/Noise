within Modelica_Noise.Blocks;
package Noise "Library of noise blocks"
  extends Modelica.Icons.Package;


  annotation (Icon(graphics={Line(
      points={{-84,0},{-54,0},{-54,40},{-24,40},{-24,-70},{6,-70},{6,80},
          {36,80},{36,-20},{66,-20},{66,60}})}), Documentation(info="<html>
<p>
This sublibrary contains blocks that generate <b>reproducible noise</b> with pseudo random
numbers. Reproducibility is important when designing control systems,
either manually or with optimization methods (for example when changing a parameter or a component
of a control system and re-simulating, it is important that the noise does not change, because
otherwise it is hard to determine whether the changed control system or the differently
computed noise has changed the behaviour of the controlled system).
Many examples how to use the Noise blocks are provided in sublibrary
<a href=\"modelica://Modelica_Noise.Blocks.Examples.NoiseExamples\">Blocks.Examples.NoiseExamples</a>.
</p>


<h4>Global Options</h4>

<p>
When using one of the blocks of this sublibrary, on the same or a higher level,
block <a href=\"Modelica_Noise.Blocks.Noise.GlobalSeed\">Noise.GlobalSeed</a>
must be dragged resulting in a declaration
</p>

<pre>
   <b>inner</b> Modelica_Noise.Blocks.Noise.GlobalSeed globalSeed;
</pre>

<p>
This block is used to define global options that hold for all Noise block
instances (such as a global seed for initializing the random number generators,
and a flag to switch off noise).

<p>
Please note that only one globalSeed instance may be defined in the model due to the block's implementation! So, the block will usually reside on the top level of the model.

<h4>Reproducible Noise</h4>

<p>
In the following table the different ways are summarized
to define reproducible noise with the blocks of this sublibrary:
<p>

<blockquote>
<p>
<table border=1 cellspacing=0 cellpadding=2>
<tr><th>Name</th>
    <th>Description</th></tr>

<tr><td> GenericNoise </td>
    <td> Random values are drawn periodically according to a given distribution
         (e.g. uniform or normal distribution) at a given sample rate
         (time events are generated at the sample instants).
         Between sample instants, the output is kept constant.</td></tr>

<tr><td> BandLimitedWhiteNoise </td>
    <td> Produces band-limited white noise with normal distribution. This noise type
         is generated by a GenericNoise instance using a special parameterization.
         </td></tr>

<tr><td> globalSeed.random() </td>
    <td> Function random() is defined inside the globalSeed component.
         On a lower hierarchical level, the function can be called via an
         outer globalSeed declaration. For every call of this function, a new
         random value is returned in the range 0 ... 1.
         Since this is an impure function, it should only
         be called in a when-clause, so at an event instant. This is a more
         traditional random number generator in the seldom cases where it is needed
         to implement a special block.</td></tr>

<tr><td> globalSeed.randomInteger(..) </td>
    <td> Function randomInteger(imin=1,imax=Modelica.Constants.Integer_inf) is
         defined inside the globalSeed component. It produces random Integer
         values in the range imin ... imax.
         On a lower hierarchical level, the function can be called via an
         outer globalSeed declaration. For every call of this function, a new
         Integer random value is returned in the range  imin ... imax.
         Since this is an impure function, it should only
         be called in a when-clause, so at an event instant.</td></tr>
</table>
</p></blockquote>


<h4>Random Number Generators</h4>

<p>
The core of the noise generation is the computation of uniform random
numbers in the range 0.0 .. 1.0 (and these random numbers are transformed
afterwards, see below). This sublibrary uses the xorshift random number generation
suite developed in 2014 by Sebastiano Vigna (for details see
<a href=\"http://xorshift.di.unimi.it\">http://xorshift.di.unimi.it</a> and
<a href=\"Modelica_Noise.Math.Random.Generators\">Math.Random.Generators</a>).
These random number generators have excellent
statistical properties, produce quickly statistically relevant random numbers, even if
starting from a bad initial seed, and have a reasonable length of the internal state
vector of 2, 4, and 33 Integer elements. The short length state vectors are especially
useful if every block instance has its own internal state vector, as needed for
reproducible noise blocks. The random number generator with a length of 33 Integer
elements is suited even for massively parallel simulations where every simulation
computes a large number of random values. More details of the random number
generators are described in the documentation of package
<a href=\"Modelica_Noise.Math.Random.Generators\">Math.Random.Generators</a>.
The blocks in this sublibrary allow to select the desired generator, but
also user-defined generators.
</p>


<h4>Distributions</h4>

<p>
The uniform random numbers in the range 0.0 .. 1.0 are transformed to a desired
random number distribution by selecting an appropriate <b>distribution</b> or
<b>truncated distribution</b>. For an example of a truncated distribution, see the following
diagram of the probabibilty density function of a normal distribution
compared with its truncated version:
</p>

<p><blockquote>
<img src=\"modelica://Modelica_Noise/Resources/Images/Math/Distributions/TruncatedNormal.density.png\">
</blockquote></p>

<p>
The corresponding inverse cumulative distribution functions are shown in the next diagram:
</p>


<p><blockquote>
<img src=\"modelica://Modelica_Noise/Resources/Images/Math/Distributions/TruncatedNormal.quantile.png\">
</blockquote></p>

<p>
When providing an x-value between 0.0 .. 1.0 from a random number generator, then the truncated
inverse cumulative probability density function of a normal distribution transforms this value into the
desired band (in the diagram above to the range: -1.5 .. 1.5). Contrary to a standard distribution,
truncated distributions have the advantage that the resulting random values are guaranteed
to be in the defined band (whereas a standard normal distribution might also result in any value;
when modeling noise that is known to be in a particular range, say &plusmn; 0.1 Volt,
then with the TruncatedNormal distribution it is guaranted that random values are only
generated in this band). More details of truncated
distributions are given in the documentation of package
<a href=\"Modelica_Noise.Math.Distributions\">Math.Distributions</a>.
In the blocks of this sublibrary, the desired distribution, truncated disribution or also
a user-defined distribution can be selected.
</p>
</html>", revisions="<html>
<p>
<table border=1 cellspacing=0 cellpadding=2>
<tr><th>Date</th> <th align=\"left\">Description</th></tr>

<tr><td valign=\"top\"> June 22, 2015 </td>
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
end Noise;

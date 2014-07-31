within Noise;
block EventBasedNoise "A noise generator based on discrete time events"
  extends Modelica.Blocks.Interfaces.SO;
  import Noise.Utilities.Auxiliary;

//
//
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
// We require an inner globalSeed
  outer GlobalSeed globalSeed;

//
//
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
// Define a seeding function (this is hidden from the user)
public
  parameter Boolean useGlobalSeed = true
    "= true: global seed influences random numbers. = false: global seeed is ignored"
    annotation(choices(checkBox=true),Dialog(tab="Advanced",group = "Initialization"));
  parameter Integer localSeed = Auxiliary.hashString(Auxiliary.removePackageName(getInstanceName()))
    "The local seed for initializing the random number generator"
    annotation(Dialog(tab="Advanced",group = "Initialization"));
  final parameter Integer globalSeed0 = if useGlobalSeed then globalSeed.seed else 0
    "The global seed, which is atually used";
public
  parameter Integer stateSize = 33
    "The number of states used in the random number generator"
    annotation(Dialog(tab = "Advanced", group = "State management"));
  Integer state[stateSize] "The internal states of the random number generator";
protected
  replaceable function Seed = Noise.Seed.xorshift64star
    constrainedby Noise.Utilities.Interfaces.Seed
    "The seeding function to be used";

//
//
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
// Define distribution (implicitly contains the default random number generator)
public
  replaceable function distribution = Noise.Distributions.Uniform
    constrainedby Noise.Utilities.Interfaces.Distribution
    "Choice of distributions of the random values"
    annotation(choicesAllMatching=true, Dialog,
    Documentation(revisions="<html>
<p><img src=\"modelica://Noise/Resources/Images/dlr_logo.png\"/> <b>Developed 2014 at the DLR Institute of System Dynamics and Control</b> </p>
</html>", info="<html>
<p>This replaceable function is used to design the distribution of values generated by the PRNG block. You can redeclare any function from here: <a href=\"Noise.PDF\">Noise.PDF</a>.</p>
</html>"));

//
//
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
// Define sampling properties
public
  parameter Modelica.SIunits.Time startTime = 0.5
    "Start time for sampling the raw random numbers"
    annotation(Dialog);
  parameter Modelica.SIunits.Time samplePeriod = 0.01*10
    "Period for sampling the raw random numbers"
    annotation(Dialog);

//
//
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
// A switch to turn off noise generation
public
  parameter Boolean enableNoise = globalSeed.enableNoise
    "=false: Use constant output signal. =true: Use noise generation"
    annotation(choices(choice=true "true",
                       choice=false "false",
                       choice=globalSeed.enableNoise "inherit from globalSeed"),
               Dialog(tab="Advanced",group = "Enable/Disable"));
  parameter Real y_off = 0 "Output value, if disabled"
    annotation(Dialog(tab="Advanced",group = "Enable/Disable"));

//
//
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
// Define a buffer to reduce sampling
public
  parameter Integer bufferSize(min=1) = 1
    "The size of the random number buffer (reduces generated time events)"
    annotation(Dialog(tab = "Advanced", group = "State management"));
  final parameter Integer bufferOverlap(min=0) = 5;
  discrete Real buffer[bufferSize+2*bufferOverlap-1];

//
//
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
// Generate the raw random numbers
public
  Real bufferStartTime "The last time we have filled the buffer";

// Initialize the states and buffers
initial algorithm
  bufferStartTime := time;
  state := Seed(localSeed=localSeed, globalSeed=globalSeed0, stateSize=stateSize);
  for i in 1:size(buffer,1) loop
    (buffer[i],state) := distribution(generator=globalSeed.generator, stateIn=state);
  end for;

// Initialize the states and buffers...
// At the first sample, we simply use the initial buffer
algorithm
  when time >= startTime then
    bufferStartTime := time;

  // At the following samples, we shift the buffer and fill the end up
  elsewhen sample(startTime,samplePeriod*bufferSize) then
    bufferStartTime := time;
    buffer[1:size(buffer,1)-bufferSize] := buffer[bufferSize+1:end];
    for i in (size(buffer,1)-bufferSize+1):size(buffer,1) loop
      // The generator must be passed due to a bug in Dymola.
      // So we can as well provide a switch in the globalSeed model.
      (buffer[i],state) := distribution(generator=globalSeed.generator, stateIn=state);
    end for;
  end when;

//
//
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
// Define interpolation
public
  replaceable function interpolation = Noise.Filters.ArbitraryInterpolation(kernel=Noise.Filters.Kernels.IdealLowPass,n=1)
    constrainedby Noise.Utilities.Interfaces.Filter
    "Choice of various filters for the frequency domain"
    annotation(choicesAllMatching=true,
    Documentation(revisions="<html>
<p><img src=\"modelica://Noise/Resources/Images/dlr_logo.png\"/> <b>Developed 2014 at the DLR Institute of System Dynamics and Control</b> </p>
</html>", info="<html>
<p>This replaceable function is used to design the distribution of frequencies generated by the PRNG block. You can redeclare any function from here: <a href=\"Noise.PSD\">Noise.PSD</a>.</p>
</html>"));

//
//
// // // // // // // // // // // // // // // // // // // // // // // // // // // // // //
// Call the interpolation with the buffer as input
equation
  y = if time >= startTime then interpolation(buffer=buffer,kernel=function Noise.Filters.Kernels.IdealLowPass(B=0.5),n=4,
                                              offset=(time-bufferStartTime) / samplePeriod + bufferOverlap) else 0;
public
  Real y2;
  Real y3;
equation
  y2 = if time >= startTime then interpolation(buffer=buffer,kernel=Noise.Filters.Kernels.Linear,n=2,
                                              offset=(time-bufferStartTime) / samplePeriod + bufferOverlap) else 0;
  y3 = if time >= startTime then Noise.Filters.SampleAndHold(buffer=buffer,
                                              offset=(time-bufferStartTime) / samplePeriod + bufferOverlap) else 0;

  annotation (Icon(coordinateSystem(preserveAspectRatio=false, extent={{-100,-100},
            {100,100}}),
                   graphics={
        Rectangle(
          extent={{-80,-10},{-100,10}},
          lineThickness=0.5,
          fillColor={135,135,135},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None),
        Rectangle(
          extent={{-60,-10},{-80,58}},
          lineThickness=0.5,
          fillColor={175,175,175},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{-20,-78},{-40,10}},
          lineThickness=0.5,
          fillColor={50,50,50},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{-40,-60},{-60,10}},
          lineThickness=0.5,
          fillColor={95,95,95},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{60,-62},{40,8}},
          lineThickness=0.5,
          fillColor={95,95,95},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{40,-10},{20,88}},
          lineThickness=0.5,
          fillColor={238,238,238},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{0,-10},{-20,76}},
          lineThickness=0.5,
          fillColor={215,215,215},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{20,-10},{0,58}},
          lineThickness=0.5,
          fillColor={175,175,175},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{80,-10},{60,76}},
          lineThickness=0.5,
          fillColor={215,215,215},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Rectangle(
          extent={{100,-10},{80,56}},
          lineThickness=0.5,
          fillColor={175,175,175},
          fillPattern=FillPattern.Solid,
          pattern=LinePattern.None,
          lineColor={0,0,0}),
        Line(
          points={{-94,-2},{-74,18},{-56,-42},{-30,-68},{-14,38},{6,12},{26,58},
              {46,-42},{68,38},{96,-2}},
          color={255,0,0},
          thickness=0.5,
          smooth=Smooth.Bezier)}),
             defaultComponentName = "prng",
    Documentation(revisions="<html>
<p><img src=\"modelica://Noise/Resources/Images/dlr_logo.png\"/> <b>Developed 2014 at the DLR Institute of System Dynamics and Control</b> </p>
</html>",
        info="<html>
<p>This block is used to generate stochastic signals based on pseudo-random numbers.</p>
<p>By default the block generates a discrete signal changing at the frequency of 100Hz with uniformly distributed random numbers between 0 and 1.</p>
<p>To change the default behavior, you can choose a different random number generator, a different probability distribution or a different power spectral density.</p>
<h4><span style=\"color:#008000\">Choosing the random number generator (RNG)</span></h4>
<p>Determine the function used to generate the pseudo-random numbers. All of these functions are designed in such a way that they return a pseudo-random number between 0 and 1 with an approximate uniform distribution.</p>
<p>There are two types of random number generators: Sample-Based RNGs and Sample Free RNGs.</p>
<ol>
<li>Sample-Based RNGs are based on a discrete state value that is changed at certain sample times. Hence these generators cause many time events.</li>
<li>Sample-Free RNGs are based on the continuous time signal and transform it into a pseudo-random signal. These generators do not cause events.</li>
</ol>
<p>Whether to better use sample-free or sample-based generators is dependent on the total system at hand and cannot be generically answered. If, however, the resulting signal shall be continuous (due to applying a PSD) then we propose to use sample-free RNGs.</p>
<h4><span style=\"color:#008000\">Choosing the probability distribution function (PDF)</span></h4>
<p>The pseudo-random numbers are per se uniformly distributed between 0 and 1. To change the distribution of the pseudo-random number generators you can choose an appropriate function.</p>
<p>Each function may have its individual parameters for defining the characteristics of the corresponding PDF. </p>
<h4><span style=\"color:#008000\">Choosing the power spectral density (PSD)</span></h4>
<p>The power spectral density function defines the spectral characteristics of the output signal. In many cases it is used to generate a continuous pseudo-random signal by interpolation or filtering with certain charactistics w.r.t frequency and variance.</p>
<p>Many Ready-to-use PSD are offered. The advantage to use a PDF to a classic PT1-element is that no continuous time states are added to the system. The PSD implementation is based on discrete convolution and the use of a PSD may change the characteristics of the PDF. For more information see the reference included below.</p>
<h4><span style=\"color:#008000\">Determine the sample frequency</span></h4>
<p>The sample frequency determines the frequency of changes of the pseudo-random numbers. </p>
<p>For sample-free generators it is possible to apply an infinite frequency. Here the change is only limited by the numerical precision and determined by the step-size control of the applied ODE-solver. When using infinite frequency, PSDs cannot be meaningfully applied anymore.</p>
<p>The sample start time is only relevant if a sample-based generator is used.</p>
<h4><span style=\"color:#008000\">Enable/Disable the block</span></h4>
<p>The block can be disabled by the Boolean flag enable. A constant output value is then used instead.</p>
<h4><span style=\"color:#008000\">Determine the seed values</span></h4>
<p>All RNGs need to be seeded. With the same seed value an RNG will generate the same signal every simulation run. If you want to do multiple simulation runs for stochastic analysis, you have to determine a different seed for each run.</p>
<p>The seed value is determined by a local seed value. This value may be combined with a global seed value from the outer model &QUOT;globalSeed&QUOT;. </p>
<p>The use of the local seed value is to make different instances of the PRNG block to generate different (uncorrelated) random signals. The use of the global seed value is to determine a new seeding for the complete system.</p>
<h4><span style=\"color:#008000\">Background Information</span></h4>
<p>To get better understanding, you may look at the examples or refer to the paper:</p>
<p>Kl&ouml;ckner, A., van der Linden, F., &AMP; Zimmer, D. (2014), <a href=\"http://www.ep.liu.se/ecp/096/087/ecp14096087.pdf\">Noise Generation for Continuous System Simulation</a>.<br/>In <i>Proceedings of the 10th International Modelica Conference</i>, Lund, Sweden. </p>
<p>This publication can also be cited when you want to refer to this library.</p>
</html>"));
end EventBasedNoise;

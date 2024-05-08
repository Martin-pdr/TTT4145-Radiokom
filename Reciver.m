clear all;

    % Receiver Adalm Pluto
Rx = sdrrx('Pluto');
    Rx.CenterFrequency = 868e6;
    Rx.BasebandSampleRate = 5e5;
    Rx.SamplesPerFrame = 418*10; 
    Rx.OutputDataType = 'double';
    Rx.ShowAdvancedProperties = true;
    Rx.GainSource = 'AGC Slow Attack';
    % Rx.EnableBurstMode = true;
    % Rx.NumFramesInBurst = 5;
    Ts = 1/Rx.BasebandSampleRate; % Sample time
    Frame_Tid = Ts * Rx.SamplesPerFrame; % En periode må også ganges med burst mode

    % Automatic gain_Controll
agc = comm.AGC;
    agc.AdaptationStepSize = 0.01;
    agc.DesiredOutputPower = 1;
    agc.AveragingLength = 100;  % Rx.SamplesPerFrame;
    agc.MaxPowerGain = 7;

    % Coarse Frequency Compensator
CoarseFreqComp = comm.CoarseFrequencyCompensator;
    CoarseFreqComp.Modulation = 'QPSK';
    CoarseFreqComp.Algorithm = "FFT-based";
    CoarseFreqComp.SampleRate = Rx.BasebandSampleRate;

    % Raised Cosine Receive Filter
RxFilt = comm.RaisedCosineReceiveFilter;
    RxFilt.RolloffFactor = 0.5; % Roll of factor er samme for alle filter.
    RxFilt.InputSamplesPerSymbol =  10; % Hvor mange samples er et filter
    RxFilt.FilterSpanInSymbols = 6;
    RxFilt.DecimationFactor = 1;

    % Symbol Synchronizer
SymbolSynchronizer = comm.SymbolSynchronizer;
    SymbolSynchronizer.Modulation = "PAM/PSK/QAM";
    SymbolSynchronizer.TimingErrorDetector = "Gardner (non-data-aided)";
    SymbolSynchronizer.SamplesPerSymbol = RxFilt.InputSamplesPerSymbol/RxFilt.DecimationFactor;
    SymbolSynchronizer.DampingFactor = 1; % The damping factor affects the loop filter s response speed. A value between 0.7 and 1.0 is often suitable. You can start with:
    SymbolSynchronizer.NormalizedLoopBandwidth = 0.01; % This parameter controls the bandwidth of the loop filter. A value between 0.01 and 0.1 is typical.
    SymbolSynchronizer.DetectorGain = 2.7; % The detector gain determines how aggressively the timing error is corrected. A value around 3.0 is often reasonable.

    % Carrier Synchronizer
CarrierSynchronizer = comm.CarrierSynchronizer;    
    CarrierSynchronizer.Modulation  = "QPSK";          
    CarrierSynchronizer.SamplesPerSymbol = 1;          
    CarrierSynchronizer.DampingFactor = 0.707;           
    CarrierSynchronizer.NormalizedLoopBandwidth = 0.01;

        % Barker Code
BarkerCode = comm.BarkerCode;
    BarkerCode.Length = 13;
    BarkerCode.SamplesPerFrame = 26;
    BarkerCode.OutputDataType = 'double'; 
    Barker = (BarkerCode() + 1)/2; % Generate a barker sequence
    BarkerSymbols = nrSymbolModulate((Barker), "QPSK");

    % PreAmble detector
preAmbDetector = comm.PreambleDetector;
    preAmbDetector.Input = 'Symbol';
    preAmbDetector.Preamble = BarkerSymbols; 
    preAmbDetector.Detections = 'All';  
    preAmbDetector.Threshold = BarkerCode.SamplesPerFrame/2 - 2;

%%
cd1 = comm.ConstellationDiagram; %cd1.SamplesPerSymbol = 10;


%% Reciver
teller = 0;
frameSize = Rx.SamplesPerFrame; framesToCollect = 70000*1;
data = zeros(Rx.SamplesPerFrame/RxFilt.InputSamplesPerSymbol, framesToCollect); Action1 = false; Buffer = zeros(191, 1); BLen = 0;
Samplingtid = Frame_Tid * framesToCollect; PhaseShift = 1;
Message = ones(217, 100);
fprintf('Start:\n\tSampler data i %d sekunder.\n', round(Samplingtid));
pause(2);
for frame = 1:framesToCollect
    [d0, datavalid, overflow] = Rx();
    if not(datavalid); warning("DataInvalid"); elseif overflow; warning("Owerflow i frame %d", frame);  
    else 
        d0 = agc(d0);
        [d1, freqOffset1] = CoarseFreqComp(d0); %if abs(freqOffset1) > 500; Rx.FrequencyCorrection = Rx.FrequencyCorrection + sign(freqOffset1) * 0.07; fprintf('\nOffset = %d, FrequencyCorrection = %d', round(freqOffset1), Rx.FrequencyCorrection); end        
        d2 = RxFilt(d1); d3 = SymbolSynchronizer(d2); d4 = CarrierSynchronizer(d3) * PhaseShift; 
        StartList = preAmbDetector(d4) + 1;        
        data(1:length(d4), frame) = d4;
        cd1(d4);

        if Action1 
            Diff2 = 191 - BLen;
            Bits = nrSymbolDemodulate(d4(1:ceil(Diff2/2)), 'QPSK', DecisionType='hard');
            Buffer(BLen + 1:191) = Bits(1:Diff2);
            bits2ASCII(double(Buffer(1:91)), 1);
            TallString = bits2ASCII(double(Buffer(1+(7*8):91-(7*2) )), 0);
            TallDoubbl = str2double(TallString) - 100;
            teller = teller + 1;
            if ~isnan(TallDoubbl) && TallDoubbl > 0 && TallDoubbl < 850; Message(TallDoubbl, :) = Buffer(92:191); end
            Action1 = false;
        end

        if any(StartList)
            for S = 1:length(StartList)
                Start = StartList(S); Diff = 418 - Start;
                if Diff > 209
                    Action1 = false; 
                    Bits = nrSymbolDemodulate(d4(Start:Start+209), 'QPSK', DecisionType='hard');
                    Test = bits2ASCII(double(Bits(1:50)), 0);
                    if Test ~= 'Melding'; PhaseShift = PhaseShift * 1j;             
                    else
                        bits2ASCII(double(Bits(1:91)), 1);
                        TallString = bits2ASCII(double(Bits(1+(7*8):91-(7*2) )), 0);
                        TallDoubbl = str2double(TallString) - 100;
                        teller = teller + 1;



                        if ~isnan(TallDoubbl) && TallDoubbl > 0 && TallDoubbl < 850; Message(TallDoubbl, :) = Bits(92:191); end                   
                    end
                    
                else
                    Action1 = true;
                    Bits = nrSymbolDemodulate(d4(Start:end), 'QPSK', DecisionType='hard');
                    BLen = length(Bits);
                    Buffer(1:BLen) = Bits;
                end

            
            end
        end
    end
end
%%
load("lenag_SD.mat");

figure(1);
subplot(3, 1, 1);
% imshow(lenag, []);
% title('Origianl');

subplot(2, 1, 1);
imshow(imresize(lenag, 0.2), []);
title('Transmited')

% Convert Bits Back to Image
img_reconstructed_bits = reshape(Message.', [], 1);
img_reconstructed_bits = img_reconstructed_bits(1:84872);
img_reconstructed = reshape(uint8(bin2dec(reshape(char(img_reconstructed_bits+'0'), 8, []).')), [103, 103]);
subplot(2, 1, 2);
imshow(img_reconstructed);
title("Recived");


figure(2);
subplot(1, 2, 1);
imshow(imresize(lenag, 0.2), []);
title('Transmited')

subplot(1, 2, 2);
imshow(img_reconstructed);
title("Recived");
%% Plot

% for frame = 1:framesToCollect
%     % sa1(data(:,frame));
%     % cd1(data(:,frame));
%     % sa2(d0, d1, d2);
%     % disp(frame);
%     %pause(0.5)
%     %pause(Frame_Tid);
%     plot(abs(data(:, frame))); ylim([0, 3]);
% end

%% Test

Buffer2 = Buffer;

Diff2 = 191 - BLen;
Test = nrSymbolDemodulate(d4(1:ceil(Diff2/2)), 'QPSK', DecisionType='hard');
% length(Test(1:Diff2))
% length(Buffer2(BLen+1:191))
Buffer2(BLen + 1:191) = Test(1:Diff2);


bits2ASCII(double(Buffer2(1:91)), 1);






clear all;

%% System objects

    % Transmitter Adalm Pluto
Tx = sdrtx('Pluto');
    Tx.CenterFrequency = 868e6;
    Tx.BasebandSampleRate = 5e5;
    Tx.OutputDataType = 'single';
    Tx.ShowAdvancedProperties = true;
    Tx.Gain = 0; % Endrer gain ut av 
    Ts = 1/Tx.BasebandSampleRate;

    % Filter (Raised Cosine Transmit Filter)
TxFilt = comm.RaisedCosineTransmitFilter;
    TxFilt.RolloffFactor = 0.5;
    TxFilt.OutputSamplesPerSymbol = 10; % Hvor mye upsampled filteret skal være
    TxFilt.FilterSpanInSymbols = 10;   % Filterts lengde
    TxFilt.Gain = 1;

    % Barker Code
BarkerCode = comm.BarkerCode; % Brukes for å finne når melding starter;
    BarkerCode.Length = 13;
    BarkerCode.SamplesPerFrame = 26; % Lengden til barker code øker lengden gir bedre pressisjon. 
    BarkerCode.OutputDataType = 'double';
    Barker = (BarkerCode() + 1)/2; % Generate a barker sequence

%%  Melding

Header = reshape(dec2bin(['Melding ' char(string(100)) ': ']).'-'0', 1, []).';
RandomBits = randi([0 1], 200, 1); % Random Bits
[Message, numFrames, img_bits, img] = BildeTilFrames();

%Test = Message(:, 1);
% length(Message(:, 1))
FullMessageLen = length(RandomBits) + BarkerCode.SamplesPerFrame + length(Header) + length(Message(1, :)) + 1;
FullMessage = zeros(FullMessageLen, 1);
Number = 100; T1 = FullMessageLen/2 * TxFilt.OutputSamplesPerSymbol * Ts; TMessage = T1 * length(Message(:, 1));
tic;

%%
Stopp = 150;
Teller = 0;
while true
    for I = 1:length(Message(:, 1))
        Number = Number + 1; if Number == 849 + 101; Number = 101; Teller = Teller + 1; end
        Header = reshape(dec2bin(['Melding ' char(string(Number)) ': ']).'-'0', 1, []).';
        FullMessage(1:200) = RandomBits;
        FullMessage(201:226) = Barker;
        FullMessage(227:317) = Header;
        FullMessage(318:417) = Message(I, :);
        disp(Number); %break;
       
        Tx(TxFilt([nrSymbolModulate((FullMessage), "QPSK")]));
    end
    %if toc  > 1000; break; end
    if Teller >= Stopp; break; end
end


% Convert Bits Back to Image
% img_reconstructed_bits = reshape(Message.', [], 1);
% img_reconstructed_bits = img_reconstructed_bits(1:length(img_bits));
% img_reconstructed = reshape(uint8(bin2dec(reshape(char(img_reconstructed_bits+'0'), 8, []).')), size(img));
%imshow(img_reconstructed);
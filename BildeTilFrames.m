function [frames, num_frames, img_bits, img] = BildeTilFrames()
    frame_size = 100;
    
    % Read image
    Bilde = load("lenag_SD.mat");   
    img = imresize(Bilde.lenag(), 0.2);
    
    % Convert Image to Bits
    img_bits = reshape(dec2bin(img(:), 8).'-'0', [], 1);
    
    % Frame Size
    %frame_size = 100; % Change this to your desired frame size
    
    % Number of Frames
    num_frames = ceil(length(img_bits)/frame_size);
    
    % Initialize frames
    frames = zeros(num_frames, frame_size);
    
    % Fill frames with image bits
    for i = 1:num_frames
        start_index = (i-1)*frame_size + 1;
        end_index = min(i*frame_size, length(img_bits));
        frames(i, 1:(end_index-start_index+1)) = img_bits(start_index:end_index);
    end
end
    


    